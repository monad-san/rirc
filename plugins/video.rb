require 'mechanize'
require 'nokogiri'
require 'open-uri'

class YouTube
  attr_reader :id

  def initialize(url, dest, param)
    @mp4fmt = [38, 37, 22, 18]
    @url = url
    @dest = dest
    @param = param

    get_info(Nokogiri.HTML(get_swf))
  end

  def show_info
    "Video URL(fmt=#{@fmt},id=#{@id}) = " << @vurl
  end

  def fetch
    open(@dest,"wb") do |out|
      open(@vurl) do |data|
        out.write(data.read)
      end
    end
  end

  private
  def get_swf
    swf = nil
    open(@url).each do |l|
      if l =~ /var\s+swf\s*=\s*(\".+\")\;/
        swf = String.class_eval('new('<< $1.gsub(/\\u([0-9a-f]{4})/){[$1.hex].pack("U")} << ')')
      end
    end
    swf
  end

  def get_info(doc)
    urls = []
    fv = doc.at_css('embed#movie_player')["flashvars"]
    url, fmt = nil
    fv.split("&").each do |fp|
      @log.debug fp
      if fp =~ /^url\_encoded\_fmt\_stream\_map\=(.*)/ then
        URI.decode($1).split(",").each do |e|
          url = URI.decode(e.scan(/url\=(.*?)(\&|$)/)[0][0])
          if e =~ /itag\=(.*?)(\&|$)/ then
            fmt = $1.to_i
            @log.debug "URL(fmt=#{fmt}): " << url 
            urls[fmt] = url if @mp4fmt.include?(fmt)
          end
        end
      elsif fp =~ /video_id\=(.*?)(\&|$)/ then
        @id = URI.decode($1)
      end
    end

    select_stream(urls)
  end

  def select_stream(urls)
    @mp4fmt.each do |m4f|
      unless urls[m4f].nil?
        @vurl = urls[m4f]
        @fmt = m4f
        break
      end
    end
  end

end

class NicoVideo
  attr_reader :id

  def initialize(url, dest, param, user, pass)
    @agent = Mechanize.new
    @nv_account = [user, pass]

    @dest = dest
    @url = url
    @param = param

    @type= ""
    get_info
  end

  def show_info
    @log.debug "NicoVideo Info: Video ID = " << @id
    @log.debug "NicoVideo Info: Video URL = " << @vurl
    @log.debug "NicoVideo Info: type = " << @type
    raise NotSupportedFormatError if @type != "mp4"
  end

  def fetch
    File.delete(@dest) if File.exist?(@dest)
    @agent.get(URI.unescape(@vurl)).save_as(@dest)
  end

  private
  def get_info
    xml = open("http://ext.nicovideo.jp/api/getthumbinfo/#{@param}").read
    if xml =~ /video_id\>(.*?)\<\/video_id/ then
      @id = $1
    end
    if xml =~ /movie_type\>(.*?)\<\/movie_type/ then
      @type = $1
    end
    get_vurl
  end

  def get_vurl

    @agent.get('https://secure.nicovideo.jp/secure/login_form')
    @agent.page.form_with(:action => 'https://secure.nicovideo.jp/secure/login?site=niconico') do |f|
      f.field_with(:name => 'mail').value = @nv_account[0]
      f.field_with(:name => 'password').value = @nv_account[1]
      f.click_button
    end
    @agent.get("http://www.nicovideo.jp/watch/#{@id}")
    @agent.get("http://www.nicovideo.jp/api/getflv/#{@id}")
    @agent.page.body.split(/&/).each do |line|
      @vurl = $1 if line =~ /url=(.+)/
    end
  end
end

class NotSupportedFormatError < Exception; end
class DestinationAlreadyExistsError < Exception; end

class VideoBot < Btmonad::Bot
  def bot_init(config)
    super(config)
    @mp4fmt = [38, 37, 22, 18]
    @tmp_path = "/tmp/fetched.mp4"
    @mp4box_path = config["mp4box_path"]
    @audio_dir = config["audio_dir"]
    
    @nv_user = config["nv_user"]
    @nv_pass = config["nv_pass"]
  end
  
  def ch_privmsg(m)
    l = m.split
    if l[0] == "v"
      @log.debug(l)
      Thread.new(self) do |p|
        begin
          url = l[1]
          dest = l[2]
          v = nil

          if url =~ /^http\:\/\/www\.youtube\.com\/(.+)$/ then
            v = YouTube.new(url, @tmp_path, $1)
          elsif url =~ /^http\:\/\/www\.nicovideo\.jp\/watch\/(.+)$/ then
            v = NicoVideo.new(url, @tmp_path, $1, @nv_user, @nv_pass)
          else
          raise NotSupportedFormatError
          end

          v.show_info
          dest = v.id if dest.nil?
          p.notice "Fetching..."
          v.fetch
          p.notice "Fetched."
          p.privmsg "Saved extract audio: " << extract(dest)
        rescue => e
          @log.error e
        end
      end
    end
  end

  private
  def extract(dest)
    dpath = File.join(@audio_dir, "#{dest}.m4a")
    if File.exists?(dpath) then
      raise DestinationAlreadyExistsError
      return
    end
    system("#{@mp4box_path} -add #{@tmp_path}#audio -new #{dpath}")
    dpath
  end

end
