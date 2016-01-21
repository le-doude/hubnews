require 'github_api'
require 'awesome_print'

GITHUB_TOKEN = "dsfukhdsuafhdiuh"
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
