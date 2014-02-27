
module Rirc
  module Driver
    class << self

      def run
        Config.load
        Config["logfile"] ? Log.open(File.expand_path(Config["logfile"], SELF_PATH)) : Log.open
        load_bots

        Client.new(Config["host"], Config["port"], {
          :nick => Config["nick"],
          :user => Config["user"],
          :real => Config["real"],
          :pass => Config["pass"],
        }).start
      end

      private

      def load_bots
        plugin_dir = File.expand_path(Config["plugin_dir"], SELF_PATH)
        for p in Config["plugins_enabled"]
          pconf = {}
          if Config["plugins"][p]
            pconf = Config["plugins"][p]
          end
          if pconf["file"] then
            file = pconf["file"]
          else
            file = p.downcase + ".rb"
          end

          load File.join(plugin_dir, file)

          unless BotClasses[p].nil? then
            BotConfigs[p] = pconf
          else
            raise NotExistBotClassException
          end
        end
      end


    end

    BotClasses = {}
    BotConfigs = {}

  end
end

