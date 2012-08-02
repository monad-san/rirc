require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'open-uri'

class VideoBot < Btmonad::Bot
  def bot_init(config)
    super(config)

    $mp4fmt = [18, 22, 37, 38]
    $mp4box_path = config["mp4box_path"]
    $tmppath = "/tmp/btmonad_yt.mp4"
    $audio_dir = config["audio_dir"]
    $playlist = config["playlist"]
    $audio_url = config["audio_url"]

    $nv_account = [config["nv_mail"], config["nv_pass"]]
  end
  
  def ch_privmsg(m)
    if m =~ /v\s+(http\:\/\/www\.youtube\.com\/.+?|http\:\/\/www\.nicovideo\.jp\/watch\/.+?)(\s|$)/ then
      url = $1
      if url =~ /nicovideo\.jp\/watch\/(.+)/
        dl_from_nv(url, $1)
      else
        dl_from_yt(url)
      end
    end
  end

  private
  def dl_from_yt(aurl)
    Thread.new(self, aurl) do |p, url|
      swf = ""
      vurls = {}
      vid = nil
      uefsm = nil

      open(url).each do |l|
        if l =~ /var\s+swf\s+=\s+(\".+\")\;/
          swf = String.class_eval('new(' << $1.gsub(/\\u([0-9a-f]{4})/){[$1.hex].pack("U")} << ')')
        end
      end

      doc = Nokogiri.HTML(swf)
      fv = doc.css('embed#movie_player')[0]["flashvars"]
      fv.split("&").each do |fp|
        if fp =~ /^url\_encoded\_fmt\_stream\_map\=(.*)/ then
          uefsm = URI.decode($1)
        elsif fp =~ /video_id\=(.*?)(\&|$)/ then
          vid = URI.decode($1)
        end
      end
      if uefsm.nil? or vid.nil? then
        p.notice "Bad Page!"
        Thread.exit
      end
      
      uefsm.split(",").each do |uefs|
        gu = URI.decode(uefs.scan(/url\=(.*?)(\&|$)/)[0][0])
        if uefs =~ /itag\=(.*?)(\&|$)/ then
          fmt = $1.to_i
          vurls[fmt] = gu if $mp4fmt.include?(fmt)
        end
      end

      $mp4fmt.each do |m4f|
        next if vurls[m4f].nil?

        p.notice "Fetching..." # (fmt=#{m4f}) : #{vurls[m4f]}"
        open($tmppath,"wb") do |out|
          open(vurls[m4f]) do |data|
            out.write(data.read)
          end
        end
        spath = File.join($audiodir, "#{vid}.m4a")
        wspath = File.join($audiourl, "#{vid}.m4a")
        if File.exists?(spath) then
          p.notice "Already exists : #{vid}.m4a"
          break
        end
        system("#{$m4bpath} -add #{$tmppath}#audio -new #{spath}")
        #puts $?
        open(File.join($audiodir, $plname), "a") do |f|
          f.puts(wspath)
        end
        p.privmsg "Fetched : #{vid}.m4a"
        break
      end
    end
  end

  def dl_from_nv(aurl, ano)
    Thread.new(self, aurl, ano) do |p, url, no|
      @agent = Mechanize.new
      @agent.get('https://secure.nicovideo.jp/secure/login_form')
      @agent.page.from_with(:action => 'https://secure.nicovideo.jp/secure/login?site=niconico') do |f|
        f.field_with(:name => 'mail').value = $nv_account[0]
        f.field_with(:name => 'mail').value = $nv_account[1]
        f.click_button
      end
      @agent.get(url)
      @agent.get("http://www.nicovideo.jp/api/getflv/#{no}")
      @agent.page.body.split(/&/).each do |line|
        vurl = $1 if line =~ /url=(.+)/
      end

      p.notice "Fetching..."
      @agent.get(URI.unescape(vurl)).save_as($tmppath)
    
      spath = File.join($audiodir, "#{no}.m4a")
      wspath = File.join($audiourl, "#{no}.m4a")
      if File.exists?(spath) then
        p.notice "Already exists : #{no}.m4a"
        break
      end
        system("#{$m4bpath} -add #{$tmppath}#audio -new #{spath}")
        #puts $?
        open(File.join($audiodir, $plname), "a") do |f|
          f.puts(wspath)
        end
        p.privmsg "Fetched : #{vid}.m4a"
        break
      end
    end
  end
end
