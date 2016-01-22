require "hubnews/version"
require "yaml"

module Hubnews
  # Your code goes here...

  def run(filename)
    config = YAML::load_file filename



  end

end
