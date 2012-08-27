
module Btmonad
  class Bot

    attr_reader :channel
    
    def initialize(post, config, channels, is_logged_in)
      @log = Log.plugin_logger(self.class.name)
      @post = post
      @channels = channels
      @ili = is_logged_in

      if !config["channel"].nil? then
        @owning_chs = [config["channel"]]
      elsif !config["channels"].nil? then
        @owning_chs = config["channels"]
      else
        @owning_chs = []
      end

      bot_init(config)
      if @ili == true then
        join_owing_chs
        on_active
      end
    end

    def bot_init(config)
    end
    
    def join_owing_chs
      for ch in @owning_chs
        join(ch)
      end
    end

    def close
      Log.debug("Bot Killed: #{self}")
      for ch in @owning_chs
        part(ch)
      end
    end
    
    def part(ch)
      Log.debug("Part Stack: #{@channels}")
      if @channels.has_key?(ch) then
        @channels[ch] -= 1
        Log.debug("Part Judge(#{ch}): #{@channels[ch]}")
        if @channels[ch] <= 0 then
          @post.call 'PART', ch
          @channels.delete(ch)
        end
      end
    end

    def join(ch)
      unless @channels.has_key?(ch) then
        @post.call 'JOIN', ch
        @channels[ch] = 0
      end
      @channels[ch] += 1
      Log.debug("Join Stack: #{@channels}")
    end
    
    def privmsg(s)
      for ch in @owning_chs
        @post.call 'PRIVMSG', ch, s
      end
    end
    
    def notice(s)
      for ch in @owning_chs
        @post.call 'NOTICE', ch, s
      end
    end

    def nick(s)
      @post.call 'NICK', s
      Btmonad::Config["nick"] = s
    end
    
    def on_rpl_welcome(m)
      @ili = true
      join_owing_chs
      on_active
    end

    def on_privmsg(m)
      if !@owning_chs.nil? && @owning_chs.include?(m[0]) then
        ch_privmsg(m[1]) if respond_to?(:ch_privmsg)
      end
    end

    def on_notice(m)
      if !@owning_chs.nil? && @owning_chs.include?(m[0]) then
        ch_notice(m[1]) if respond_to?(:ch_notice)
      end
    end

    def on_kick(m)
      exit(1) if m[1] == Btmonad::Config["nick"]
    end
    
    def on_message(m)
    end
    
    def self_message(command, *args)
    end

    def on_active
    end

    def self.inherited(c)
      Driver::BotClasses[c.to_s] = c
    end
  end
end

