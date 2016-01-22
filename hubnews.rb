require 'octokit'
require 'slack'
require 'yaml'
require 'awesome_print'
require 'byebug'

GITHUB_TOKEN = ENV["GITHUB_TOKEN"]
SLACK_TOKEN = ENV["SLACK_TOKEN"]

raise "No GITHUB_TOKEN sysenv found" unless GITHUB_TOKEN
raise "No SLACK_TOKEN sysenv found" unless SLACK_TOKEN

LGTM_NEEDED = 2

repository = 'en-japan/waza'
channel = '#waza-dev'

github = Octokit::Client.new access_token: GITHUB_TOKEN

open_pull_request = github.pull_requests(repository, state: 'open').map { |pr| [pr[:number], pr] }.to_h

report = open_pull_request.map do |number, pr|

  number = pr[:number]

  lgtmh = github.issue_comments(repository, number).map do |comment|
    [comment[:user][:login], comment[:body].include?('LGTM')]
  end.to_h

  [number, lgtmh]

end.to_h


what = YAML::load_file File.join(File.dirname(File.expand_path(__FILE__)), 'commiters.yml')

slack = Slack::Client.new token: SLACK_TOKEN


full_report="*PR report* on _#{repository}_ at #{DateTime.now.to_s}\n"

open_pull_request.each do |number, pr|
  title = pr[:title]
  approvers = nil
  status = if (title.downcase =~ /deliver|fix/).nil?
             "Work in progress. :derp:"
           else
             approvers = report[number].select { |k, v| v }.keys
             if approvers.size < LGTM_NEEDED
               "Awaiting review. :zzz: "
             else
               "Ready to merge. :lgtm:"
             end
           end


  message = "<#{pr._links.self.href}|#{title}>\n"\
            "> status: *#{status}*\n"

  message += "> lgtmed by: #{approvers.map {|ghname| "@" + what[ghname] || ghname}.join(", ")}\n" if approvers && approvers.any?

  full_report += ("\n" + message) unless message.empty?
end

slack.chat_postMessage(channel: channel, text: full_report, link_names: 1)
