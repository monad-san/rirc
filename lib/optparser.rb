module Btmonad
  module OptParser
    class << self
      def parse!(argv)
        @op.parse!(argv)
      end
    end

    @op = OptionParser.new do |opt|
      opt.program_name = 'Btmonad'

      opt.on('-r', '--rc file', "spacify configfile") do |file|
        Btmonad::DCONF_FILE = file
      end

      opt.on('-d', '--directory directory', "set directory where configfile is existed") do |dir|
        Btmonad::DCONF_PATH = dir
      end

      opt.on('--quiet', "quiet by inactivate") do |v|
        Btmonad::daemon
      end
    end
  end
end

