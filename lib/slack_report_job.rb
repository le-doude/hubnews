class SlackReportJob

  attr_reader :name, :repositories, :channel

  def initialize(name, conf)
    @name = name

    github_conf = conf['github']
    raise "No Github configuration" unless github_conf
    raise "No Gihut access token" unless github_conf['token']

    # @github = Octokit::Client.new access_token: github_conf['token']

    @repositories = github_conf['repos'].map do |n, conf|
      [n, Repository.new(github_conf['token'], conf)]
    end.to_h

    slack_conf = conf['slack']
    raise "No SLACK configuration provided" unless slack_conf
    raise "No SLACK access token found" unless slack_conf['token']

    @slack = Slack::Client.new token: slack_conf['token']
    @channel = slack_conf['channel']
  end

  class Repository

    attr_reader :id, :approval, :commiters

    def initialize(token, conf)
      @github_client = Octokit::Client.new access_token: token
      @id = conf['id']
      @commiters = conf['commiters']
      temp = conf['approval']
      @approval = case temp
                    when nil, "quorum", "majority"
                      ((commiters.size - 1) / 2) + 1
                    when "one"
                      1
                    else
                      temp.to_i
                  end
    end

    def pull_requests
      @pr_data ||= @github_client.pull_requests(id, state: 'open').map { |d| [d['number'], d] }
    end

    def lgtm_report(pr_number)
      lgtmh = Hash.new { |hsh, key| hsh[key] = false }
      @github_client.issue_comments(id, pr_number).each do |comment|
        lgtmh[comment.user.login] ||= comment[:body].include?('LGTM')
      end
      lgtmh
    end

    def pull_request_status_reports
      wip = []
      reports = []

      pull_requests.each do |number, pr|
        title = pr[:title]
        if title.downcase =~ /wip/ || (title.downcase =~ /deliver|fix/).nil?
          wip << pr
        else
          author = pr[:user]
          page = pr[:_links][:html][:href]

          lgtms = lgtm_report(number)
          approvers = lgtms.select { |k, v| v }

          waiting_on = commiters.select { |k, v| k != author[:login] && !approvers.include?(k) }
          color, fields = if approvers.size < approval
                            ['warning', [
                                {
                                    title: "Status",
                                    value: "Awaiting reviews.",
                                    short: true
                                },
                                {
                                    :title => 'Pending review from',
                                    :value => waiting_on.values.map { |slack_name| "@" + slack_name }.join(", "),
                                    :short => false
                                }
                            ]]
                          else
                            ['good', [
                                {
                                    title: "Status",
                                    value: "Ready to merge.",
                                    short: true
                                }
                            ]]
                          end

          reports << {
              :title => title,
              :title_link => page,
              :color => color,
              :author_name => author[:login],
              :author_link => author[:html_url],
              :author_icon => author[:avatar_url],
              :fields => fields
          }

        end
      end

      reports << {
          :title => "Work in progress",
          :color => '#ac1b82',
          :thumb_url => "https://slack-files.com/T04UCLB3U-F0K96M68L-a18c837f49",
          :fields => wip.group_by { |pr| pr.user.login }.map do |user, pr_list|
            {
                :title => "#{user} (#{pr_list.size})",
                :value => pr_list.map do |pr|
                  " <#{pr._links.html.href}|##{pr.number}>"
                end.join(', ')
            }
          end
      }

      reports

    end

  end

  def send_report
    @repositories.each do |name, repo|
      reports = repo.pull_request_status_reports

      @slack.chat_postMessage(channel: channel,
                              text: "Pull Requests Report",
                              link_names: 1,
                              username: "PR status: #{repo.id}",
                              icon_emoji: ":octocat:",
                              attachments: reports.to_json)

    end
  end

end