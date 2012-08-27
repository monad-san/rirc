
module Btmonad
  module Log
    class << self
      def open(path = "debug_log")
        FileUtils.mkdir_p(File.dirname(path)) unless FileTest.exist?(File.dirname(path))
        @@log = Logger.new(path)
        @@log.level = Logger::DEBUG
      end

      def debug(m)
        @@log.debug(m)
      end

      def plugin_logger(plugin_name)
        PluginLogger.new(@@log, plugin_name)
      end
    end

    class PluginLogger
      def initialize(log, name)
        @log = log
        @name = name
      end

      def debug(m)
        @log.debug("[#{@name}] #{m}")
      end
    end

  end
end

