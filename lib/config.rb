
module Btmonad
  module Config
    class << self
      def load(path = DCONF_PATH)
        @@conf = YAML.load_file(path)
      end

      def [](k)
        @@conf[k]
      end
    end
  end
end

