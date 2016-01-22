require 'octokit'
require 'awesome_print'
require 'byebug'

GITHUB_TOKEN = ENV["GITHUB_TOKEN"]
SLACK_TOKEN = ENV["SLACK_TOKEN"]

raise "No GITHUB_TOKEN sysenv found" unless GITHUB_TOKEN
raise "No SLACK_TOKEN sysenv found" unless SLACK_TOKEN


repository = 'en-japan/waza'

github = Octokit::Client.new access_token: GITHUB_TOKEN

open_pull_request = github.pull_requests(repository, state: 'open').map {|pr| pr[:number]}

report = open_pull_request.map do |number|

  lgtmh = github.issue_comments(repository, number).map do |comment|
    [comment[:user][:login], comment[:body].include?('LGTM')]
  end.to_h

  [number, lgtmh]

end.to_h

ap report
