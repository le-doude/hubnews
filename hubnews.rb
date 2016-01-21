require 'github_api'
require 'awesome_print'

GITHUB_TOKEN = "763a6a109a47bedb1045035964fbfae709998e6e"
SLACK_TOKEN = "kajshfdjkshf"

github = Github.new oauth_token: GITHUB_TOKEN
l = github.pull_requests.list('en-japan', 'waza')
l.each do |pr|
  if pr[:state] == "open"
    comments = github.pull_requests.comments.list 'en-japan', 'waza', number: pr[:number]
    comments.each do |comment|
      ap comment
    end
  end
end
