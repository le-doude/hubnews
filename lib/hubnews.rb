require "hubnews/version"
require "yaml"
require 'config_helper'

module Hubnews
  # Your code goes here...

  def run(projects= nil, filename = 'config.yml')
    config = ConfigHelper.load_config(filename)

    projects_to_run = config.select do |k, v|
      projects.nil? || projects == k ||(projects.is_a?(Array) && projects.include?(k))
    end

    jobs = projects_to_run.map do |name, job_conf|

    end

  end

end
