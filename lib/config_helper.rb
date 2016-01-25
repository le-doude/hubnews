require 'erb'
require 'yaml'

module ConfigHelper

  class << self

    def load_config(*args)
      YAML.load(ERB.new(File.read(File.join(*args))).result)
    end

  end

end