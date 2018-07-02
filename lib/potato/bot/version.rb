module Potato
  module Bot
    VERSION = '0.1.1'.freeze

    def self.gem_version
      Gem::Version.new VERSION
    end
  end
end
