require 'octokit'
require 'slack'
require 'yaml'
require 'awesome_print'
require 'byebug'

config = YAML::load_file File.join(File.dirname(File.expand_path(__FILE__)), 'config.yml')

config = config['waza']

slack_conf = config['slack']
SLACK_TOKEN = if slack_conf
                slack_conf['token']
              end || ENV["SLACK_TOKEN"]
github_config = config['github']
GITHUB_TOKEN = github_config['token'] || ENV["GITHUB_TOKEN"]

raise "No GITHUB_TOKEN sysenv found" unless GITHUB_TOKEN
raise "No SLACK_TOKEN sysenv found" unless SLACK_TOKEN

repos = github_config['repos'] || github_config['repositories']

repos.each do |repo_name, repo_conf|

  channel = slack_conf['channel']
  repository = repo_conf["id"]
  commiters = repo_conf["commiters"]
  approval = if repo_conf['approval'] == "quorum"
               ((commiters.size - 1) / 2) + 1
             else
               repo_conf['approval'].to_i
             end


  github = Octokit::Client.new access_token: (repo_conf['token'] || GITHUB_TOKEN)
  slack = Slack::Client.new token: (repo_conf['slack_token'] || SLACK_TOKEN)


  open_pull_request = github.pull_requests(repository, state: 'open').map { |pr| [pr[:number], pr] }.to_h

  report = open_pull_request.map do |number, pr|
    number = pr[:number]

    comments = github.issue_comments(repository, number)
    lgtmh = Hash.new { |hsh, key| hsh[key] = false }
    comments.each do |comment|
      lgtmh[comment.user.login] ||= comment[:body].include?('LGTM')
    end

    [number, lgtmh]

  end.to_h


  full_report=""
  wip=[]

  open_pull_request.each do |number, pr|
    title = pr[:title]
    if title.downcase =~ /wip/ || (title.downcase =~ /deliver|fix/).nil? #if is work in progress
      wip << pr
    else
      approvers = report[number].select { |k, v| v }.keys
      status = if approvers.size < approval
                 "Awaiting review. :zzz: "
               else
                 "Ready to merge. :lgtm:"
               end

      message = "<#{pr._links.html.href}|#{title}> by #{commiters[pr.user.login]}\n"\
            "> status: *#{status}*\n"
      if approvers.nil? || approvers.empty? || approvers.size < 2
        lazyguys = commiters.select { |k, v| !report[number][k] && k != pr.user.login }
        message += "> awaiting from: #{lazyguys.values.map { |slack_name| "@" + slack_name }.join(", ")}\n"
      end

      full_report += ("\n" + message) unless message.empty?
    end
  end

  wip_s = wip.map { |pr| "<#{pr._links.html.href}|#{pr.number}> by #{pr.user.login}" }.join(", ")
  full_report += "\n\n currently WIP: #{wip_s}"

  slack.chat_postMessage(channel: channel, text: full_report, link_names: 1, username: "Github PR Report - repo #{repository}")
end
