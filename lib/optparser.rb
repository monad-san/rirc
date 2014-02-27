
module Rirc
  module OptParser
    class << self
      def parse!(argv)
        @op.parse!(argv)
      end
    end

    @op = OptionParser.new do |opt|
      opt.program_name = 'Rirc'

      opt.on('-r', '--rc file', "spacify configfile") do |file|
        Rirc::DCONF_FILE = file
      end

      opt.on('-d', '--directory directory', "set directory where configfile is existed") do |dir|
        Rirc::DCONF_PATH = dir
      end

      opt.on('--quiet', "quiet by inactivate") do |v|
        Rirc::daemon
      end
    end
  end
end

