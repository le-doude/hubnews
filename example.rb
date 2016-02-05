require 'octokit'
require 'slack'
require 'awesome_print'
require 'byebug'
require_relative 'lib/config_helper'
require_relative 'lib/slack_report_job'

config = ConfigHelper.load_config('config.yml')

config = config['waza']

job = SlackReportJob.new('waza', config)

job.send_report