require 'rubygems'
require 'nokogiri'
require 'open-uri'

class YouTubeBot < Btmonad::Bot
  def bot_init(config)
    super(config)

    $mp4fmt = [18, 22, 37, 38]
    $m4bpath = config["mp4box_path"]
    $tmppath = "/tmp/btmonad_yt.mp4"
    $audiodir = config["audio_dir"]
    $plname = config["playlist"]
    $audiourl = config["audio_url"]
  end
  
  def ch_privmsg(m)
    if m =~ /video\:\s*(http\:\/\/www\.youtube\.com\/.+?)(\s|$)/ then
      Thread.new(self, $1) do |p, url|
        vurls = {}
        vid = nil
        uefsm = nil

        doc = Nokogiri.HTML(open(url).read)
        fv = doc.xpath('//embed[@id="movie_player"]')[0]["flashvars"]
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
  end
end

