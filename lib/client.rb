
module Btmonad
  class Client < Net::IRC::Client

    def initialize(*args)
      super
      
      @bots = {}
      @channels = {}
      @is_logged_in = false

      @mutex = Mutex.new
      
      Driver::BotClasses.each_pair do |key, bc|
        @bots[key] = bc.new(Proc.new {|command, *args|
          post(command, *args)
          @bots.each_value do |b|
            b.self_message(command, *args)
          end
        }, Driver::BotConfigs[key], @channels, @is_logged_in)
      end
      Signal.trap(:HUP) do
        @mutex.synchronize do
          reload
        end
      end
    end

    def on_message(m)
      @mutex.synchronize do
        method_name = "on_#{(Net::IRC::COMMANDS[m.command.upcase] || m.command).downcase}"
        @bots.each_value do |b|
          b.send(method_name, m) if b.respond_to?(method_name)
          b.send("on_message",m)
        end
      end

#      true unless method_name == "on_ping" || method_name == "on_rpl_isupport" || method_name == "on_rpl_welcome"
    end

    def on_rpl_welcome(m)
      @is_logged_in = true
    end

    private

    def reload
      bots_config_diff = reload_config
      delete_bots(bots_config_diff)
      new_botclasses = reload_bots(bots_config_diff)
      apply_bots(new_botclasses)
    end
      
    def reload_config

      opc_hash = {}
      present_bots = Set[]
      diff = {:updated => {},
              :wasted  => Set[],
              :new     => {},}
      
      for op in Config["plugins_enabled"]
        opc_hash[op] = Config["plugins"][op]
      end

      Config.loadfile
      
      for p in Config["plugins_enabled"]
        pconf = {}
        if Config["plugins"][p]
          pconf = Config["plugins"][p]
        end
        present_bots.add(p)
        if @bots.key?(p) then
          if opc_hash[p].inspect != pconf.inspect then
            diff[:updated][p] = pconf
          end
        else
          diff[:new][p] = pconf
        end
      end
      wasted_bots = Set.new(@bots.keys) - present_bots
      for wb in wasted_bots
        diff[:wasted].add(wb)
      end

      diff
    end

    def delete_bots(config)
      for wbn in (config[:wasted] + config[:updated].keys).to_a
        @bots[wbn].close
        @bots.delete(wbn)
      end
    end
      
    def reload_bots(config)
      botclasses = {}
      plugin_dir = File.join(File.dirname(DCONF_PATH), Config["plugin_dir"])

      config[:new].merge(config[:updated]).each_pair do |p, pconf|
        if pconf["file"] then
          file = pconf["file"]
        else
          file = p.downcase + ".rb"
        end

        load File.join(plugin_dir, file)

        if bc = Driver::BotClasses[p] then
          Driver::BotConfigs[p] = pconf
          botclasses[p] = bc
        else
          raise NoBotClassException
        end
      end

      botclasses
    end

    def apply_bots(botclasses)
      botclasses.each_pair do |key, bc|
        @bots[key] = bc.new(Proc.new{|command, *args| post(command, *args)}, Driver::BotConfigs[key], @channels, @is_logged_in)
      end
#      STDERR.puts @bots.pretty_inspect
    end
    
  end
end

