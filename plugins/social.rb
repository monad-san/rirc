require 'net/https'
require 'oauth'
require 'json'
require 'kconv'

class TwitterGateway
  TweetTable = []
  DIGIT = 36
  MAX_TABLE_LENGTH = DIGIT**2 - 1

  BOT_USER_AGENT = "Lempicka"
  CONSUMER_KEY = "G5QFBnCLSCXNsW9JcbLUw"
  CONSUMER_SECRET = "fik8ey981xQj60AlmBhoEo0MkxESpaaRpbRGDL1Jg"

  def initialize(log, config = nil)
    @log = log
    @consumer = OAuth::Consumer.new(
      CONSUMER_KEY,
      CONSUMER_SECRET,
      :site => 'http://twitter.com'
    )
    a = config ? config : get_access_token
    @access_token = OAuth::AccessToken.new(
      @consumer,
      a["access_token"],
      a["access_secret"]
    )
  end

  def update(out, tweet, in_reply_to = nil)
    unless in_reply_to.nil? then
      to_name = TweetTable[in_reply_to.to_i(36)][:user]['screen_name']
      to_id = TweetTable[in_reply_to.to_i(36)][:id]
      tweet = "@#{to_name} #{tweet.toutf8}"
    end
    @access_token.post('/statuses/update.json',
                       'status' => tweet.toutf8,
                       'in_reply_to_status_id' => to_id
                       )
    out.notice "success update!"
  end

  def favorite(out, fav)
    to_id = TweetTable[fav.to_i(36)][:id]
    @access_token.post("/favorites/create/#{to_id}.json")
    out.notice "success favorite!"
  end

  def mainloop(out)
    itr = 0
    loop do
      begin
        connect do |json|
          if json['text']
            itr = 0 if itr > MAX_TABLE_LENGTH
            TweetTable[itr] =  { :id => json['id'], :user => json['user'] }
	    out.privmsg "[$#{itr.to_s(DIGIT)}] <#{json['user']['screen_name']}>: #{json['text']}".tojis
            itr = itr + 1
          end
        end
      rescue Timeout::Error, StandardError
        @log.debug "Reconnecting to twitter..."
      end
    end
  end

  private
  def connect
    uri = URI.parse("https://userstream.twitter.com/2/user.json")

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    https.verify_depth = 5

    https.start do |https|
      request = Net::HTTP::Get.new(uri.request_uri)
      request["User-Agent"] = BOT_USER_AGENT
      request.oauth!(https, @consumer, @access_token)

      buf = ""
      https.request(request) do |response|
        response.read_body do |chunk|
          buf << chunk

          while(line = buf[/.+?(\r\n)+/m]) != nil
            begin

              buf.sub!(line,"")
              line.strip!
              status = JSON.parse(line)
            rescue
              break
            end

            yield status
          end
        end
      end
    end
  end

  def get_access_token
    req_token = @consumer.get_request_token
    config = {}

    puts "Get Access Token:"
    puts " - 1. Open following URL: #{req_token.authorize_url}"
    puts " - 2. Enter the PIN: "
    pin = STDIN.gets.strip

    access_token = req_token.get_access_token(:oauth_verifier => pin)
    config["access_token"] = access_token.token
    config["access_secret"] = access_token.secret
    puts "Access token: #{config["access_token"]}"
    puts "Access token secret: #{config["access_secret"]}"
    config
  end
end

if $0 == __FILE__ then
  TwitterGateway.new
else
  class SocialBot < Btmonad::Bot
    def bot_init(config)
      super(config)

      @tg = TwitterGateway.new(config)
    end

    def on_active
      if @t.nil? then
        @t = Thread.new(self) do |p|
          begin
            @tg.mainloop(p)
          rescue => e
            @log.debug(e)
            retry
          end
        end
      end
    end

    def ch_privmsg(m)
      begin
        if m =~ /^(.*)\@t$/
          @tg.update(self, $1)
        elsif m =~ /^(.*)\@r\$([1-9a-z]{1,2})$/
          @tg.update(self, $1, $2)
        elsif m =~ /^f\$([1-9a-z]{1,2})/
          @tg.favorite(self, $1)
        end
      rescue => e
        @log.debug(e)
        retry
      end
    end

  end
end
