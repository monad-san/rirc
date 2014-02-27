
#
# RSSBot -- write RSS feeds
#

require 'feed-normalizer'
require 'open-uri'
require 'digest/sha2'
require 'openssl'

class FeedReader
  def initialize(log, url, min_time = Time::at(0))
    @log = log
    @url = url
    @hashes = []
  end

  def read_feeds()
    begin
      @rss = FeedNormalizer::FeedNormalizer.parse(open(@url,"r",{:ssl_verify_mode=>OpenSSL::SSL::VERIFY_NONE}))
    rescue OpenURI::HTTPError => err
      @log.debug(err)
      sleep @waitretry
      retry
    end

    @log.debug("RSS Updated: #{@hashes.length}")

    rss_items = []
    @rss.entries.each do |item|
      item_hash = Digest::SHA512.digest(item.url.inspect)
      @log.debug("Hash: #{@hashes.include?(item_hash) ? 'Included' : 'New!' } (#{item_hash.unpack('H*')[0][0..5]})#{item.title[0..10]}")
      unless @hashes.include?(item_hash) then
        rss_items.push item
        @hashes.push item_hash
        @hashes.shift if @hashes.length > 1000
      end
    end

    rss_items
  end
  
end

class RSSBot < Rirc::Bot
  def bot_init(config)
    super(config)

    @urls = config["urls"]
    @interval = config["interval"]
    @waitretry = config["waitretry"]
    @t = nil
  end

  def on_active
    frs = @urls.map {|u| FeedReader.new(@log, u) }

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
          sleep @waitretry
          retry
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
      begin
        abbr = open("http://tinyurl.com/api-create.php?url=" + url).read
      rescue OpenURI::HTTPError => err
        @log.debug(err)
        sleep @waitretry
        retry
      end
      return abbr
    end
    url
  end

  private
  def show_feeds(frs, p, is_init = false)
    frs.each do |fr|
      items = nil

      loop do
        items = fr.read_feeds
        break if items != :error
      end

      if is_init
        items = items.sort{|a, b| b.last_updated <=> a.last_updated}[0..9].reverse
      end
      items.each do |item|
        s = item.title[0..250] + " " + p.abbrurl(item.url)
        p.privmsg s.tojis
      end
    end
  end
end

