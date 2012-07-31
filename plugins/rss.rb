require 'rss'
require 'open-uri'
require 'digest/sha2'

class FeedReader
  def initialize(url, min_time = Time::at(0))
    @url = url
    @hashes = []
  end

  def read_feeds(log)
    begin
      @rss = open(@url){|feed| RSS::Parser.parse(feed.read, false)}
    rescue OpenURI::HTTPError => ex
      return :error
    end
    @rss.output_encoding = "UTF-8"
#    log.debug("RSS Updated: #{@hashes.length}")

    rss_items = []
    @rss.items.each do |item|
      item_hash = Digest::SHA512.digest(item.link.inspect)
#      log.debug("Hash: #{@hashes.include?(item_hash) ? 'Included' : 'New!' } (#{item_hash.unpack('H*')[0][0..5]})#{item.title[0..10]}")
      unless @hashes.include?(item_hash) then
        rss_items.push item
        @hashes.push item_hash
        @hashes.shift if @hashes.length > 1000
      end
    end

    rss_items
  end
  
end

class RSSBot < Btmonad::Bot
  def bot_init(config)
    super(config)

    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG

    @urls = config["urls"]
    @interval = config["interval"]
    @t = nil
  end

  def on_active
    frs = @urls.map {|u| FeedReader.new(u) }

    if @t.nil? then
      @t = Thread.new(self) do |p|
        begin
          show_feeds(frs, p, true)
          loop do
            sleep @interval
            show_feeds(frs, p)
          end
        rescue => e
          @log.debug(e)
        end
      end
    end
  end

  def close
    Thread::kill(@t)
    super
  end

  def abbrurl(url)
    if url.length >= 200 then
      abbr = open("http://tinyurl.com/api-create.php?url=" + url).read
      return abbr
    end
    url
  end

  private
  def show_feeds(frs, p, is_init = false)
    frs.each do |fr|
      items = nil

      loop do
        items = fr.read_feeds(@log)
        break if items != :error
      end

      if is_init
        items = items.sort{|a, b| b.date <=> a.date}[0..9].reverse
      end
      items.each do |item|
        s = item.title[0..250] + " " + p.abbrurl(item.link)
        p.privmsg s.tojis
      end
    end
  end
end

