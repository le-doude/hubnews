require 'github_api'
require 'awesome_print'

GITHUB_TOKEN = ENV["GITHUB_TOKEN"]
SLACK_TOKEN = ENV["SLACK_TOKEN"]

github = Github.new oauth_token: GITHUB_TOKEN

pr_to_lgtm = {}

l = github.pull_requests.list('en-japan', 'waza', state: "open")
l.each do |pr|
  lgtms = 0
  if pr[:state] == "open"
    comments = github.pull_requests.comments.list 'en-japan', 'waza', number: pr[:number]
    comments.each do |comment|
      lgtms = lgtms + 1 if comment[:body].include?("LGTM")
    end
  end
  pr_to_lgtm[pr[:number]] = lgtms
end

ap pr_to_lgtm