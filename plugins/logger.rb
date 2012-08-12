
class LoggerBot < Btmonad::Bot
  def bot_init(config)
    @log_dir = config["directory"]
    @commands = config["commands"].split(",").map! {|c| c.downcase }
    @encode = config["charset"]
  end
  
  def on_message(m)
    filename = "%Y.%m.%d.txt"
    l = Time.now.strftime("%H:%M:%S")
    c = m.command.downcase
    nick = m.prefix.split('!')[0]
    ch = m[0]
    
    if @ili && !(@commands.index(c).nil?) then
#      STDERR.print m.pretty_inspect
#      STDERR.print @ili.pretty_inspect
      if c == "privmsg" then
        l += " <#{ch}:#{nick}> " + m[1].send("to#{@encode}")
      elsif c == "notice" then
        l += " (#{ch}:#{nick}) " + m[1].send("to#{@encode}")
      elsif c == "join" then
        l += " + #{nick} (#{m.prefix}) to #{ch}"
      elsif c == "part" then
        l += " ! #{nick} (#{m[1]})"
      elsif c == "kick" then
        l += " - #{m[1]} by #{nick} from #{ch} (#{m[2]})"
      elsif c == "topic" then
        l += " Topic of channel #{ch} by #{nick}: #{m[1]}"
      elsif c == "mode" then
        if ch =~ /^(\#|\$|\%).+$/ then
          l += " Mode by #{nick}: #{m.params.join(" ")}"
        else
          return
        end
      elsif c == "nick" then
        l += " #{nick} -> #{m[0]}"

        ps = Dir.glob(File.join(File.dirname(Btmonad::DCONF_PATH), @log_dir) + "/*")
        for p in ps
          p = File.join(p, Time.now.strftime(filename))
          File.open(p,'a') {|f| f.puts l } unless p.nil?
        end
        return
      else
        return
      end

#      STDERR.puts l
      if l == "" then
        raise NoStringLineException
      end
      p = join_with_mkdir(File.dirname(Btmonad::DCONF_PATH), @log_dir, ch, Time.now.strftime(filename))
      File.open(p,'a') {|f| f.puts l } unless p.nil?
    end
  end

  def self_message(command, *m)
    filename = "%Y.%m.%d.txt"
    l = Time.now.strftime("%H:%M:%S")
    c = command.downcase
    ch = m[0]
    nick = Btmonad::Config["nick"]
    
    if @ili && !(@commands.index(c).nil?) then
#      STDERR.puts m.inspect
      if c == "privmsg" then
        l += " >#{ch}:#{nick}< " + m[1].send("to#{@encode}") 
      elsif c == "notice" then
        l += " )#{ch}:#{nick}( " + m[1].send("to#{@encode}") 
      elsif c == "topic" then
        l += " Topic of channel #{ch} by #{nick}: #{m[1]}"
      elsif c == "mode" then
        if ch =~ /^(\#|\$|\%).+$/ then
          l += " Mode by #{nick}: #{m.join(" ")}"
        else
          return
        end
      elsif c == "nick" then
        l += " My nick is changed (#{nick} -> #{m[0]})"
        ps = Dir.glob(File.join(File.dirname(Btmonad::DCONF_PATH), @log_dir) + "/*")
        for p in ps
          p = File.join(p, Time.now.strftime(filename))
          File.open(p,'a') {|f| f.puts l } unless p.nil?
        end
        return
      else
        return
      end

#      STDERR.puts l
      p = join_with_mkdir(File.dirname(Btmonad::DCONF_PATH), @log_dir, ch, Time.now.strftime(filename))
      File.open(p,'a') {|f| f.puts l } unless p.nil?
    end
  end
    
  private

  def join_with_mkdir(rootdir, *leaves)
    joined = rootdir
    dirs = leaves[0..-2]
    for d in dirs
      joined = File.join(joined, d)
      Dir.mkdir(joined) unless File.directory?(joined)
    end
    File.join(joined, leaves[-1])
  end

end

