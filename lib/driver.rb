
module Btmonad
  module Driver
    class << self

      def run
        load_config
        load_bots

        Client.new(Config["host"], Config["port"], {
          :nick => Config["nick"],
          :user => Config["user"],
          :real => Config["real"],
          :pass => Config["pass"],
        }).start
        
      end

      private

      def load_config
#        Config.setup unless File.exist?(configfile)
        Config.loadfile
      end

      def load_bots
        plugin_dir = File.join(File.dirname(DCONF_PATH), Config["plugin_dir"])
        for p in Config["plugins"]
          if p["file"] then
            file = p["file"]
          else
            file = p["class"].downcase + ".rb"
          end
          
          load File.join(plugin_dir, file)

          unless BotClasses[p["class"]].nil? then
            BotConfigs[p["class"]] = p
          else
            raise NoBotClassException
          end
        end
      end


    end

    BotClasses = {}
    BotConfigs = {}
    
  end
end

