$KCODE = 'u' unless Object.const_defined? :Encoding

unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
  $:.unshift(File.dirname(__FILE__))
end

require 'pp'
require 'set'
require 'optparse'
require 'yaml'
require 'thread'
require 'kconv'

require 'rubygems'
require 'net/irc'

module Btmonad

  require 'lib/optparser'
  require 'lib/config'
  require 'lib/bot'
  require 'lib/client'
  require 'lib/driver'

  class << self
    def daemon(nochdir = nil, noclose = nil)
      if Process.respond_to? :daemon
        Process.daemon(nochdir, noclose)
      else
        exit!(0) if fork
        Process::setsid
        exit!(0) if fork
        unless nochdir then
          Dir::chdir("/")
        end
        File::umask(0)
        unless noclose then
          STDIN.reopen("/dev/null")
          STDOUT.reopen("/dev/null","w")
          STDERR.reopen("/dev/null","w")
        end
      end
    end
  end

  OptParser.parse!(ARGV)

  DCONF_FILE = 'config.yaml' unless defined? DCONF_FILE
  DCONF_PATH = File.join(File.dirname(File.expand_path(__FILE__)), DCONF_FILE) unless defined? DCONF_PATH
end
