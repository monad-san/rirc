require 'rss'
require 'open-uri'

class FeedReader
  def initialize(url, init_time = Time::at(0))
    @read_line = init_time
    @url = url
  end

  def feed_read
    @rss = open(@url){|feed| RSS::Parser.parse(feed.read, false)}
    @rss.output_encoding = "UTF-8"
    rss_items = {}
    
    pmax_time = @read_line
    @rss.items.each{|item|
      if item.date > @read_line then
        rss_items[item.date] = item
        pmax_time = pmax_time < item.date ? item.date : pmax_time
      end
    }
    @read_line = pmax_time

    rss_items
  end
  
end

class RSSBot < Btmonad::Bot
  def bot_init(config)
    super(config)

    @urls = config["urls"]
    @interval = config["interval"]
    @t = nil
  end
  
  def on_active
    frs = @urls.map {|u| FeedReader.new(u) }

    if @t.nil? then
      @t = Thread.new(self) do |p|
        frs.each do |fr|
          sorted_feeds = []
          s = ""
          
          items = fr.feed_read
          items.sort{|a, b| b[0] <=> a[0]}.each do |d, item|
            sorted_feeds.push item
          end

          sorted_feeds[0..9].reverse.each do |item|
            s = item.title + " " + p.abbrurl(item.link)
            p.privmsg s.tojis
          end
        end
        loop do
          sleep @interval
          frs.each do |fr|
            feeds = fr.feed_read
            feeds.each_value do |item|
              s = item.title + " " + p.abbrurl(item.link)
              p.privmsg s.tojis
            end
          end
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
end

