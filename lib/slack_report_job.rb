class SlackReportJob

  attr_reader :name
  attr_reader :repositories
  attr_reader :channel

  def initialize(name, conf)
    @name = name

    github_conf = conf['github']
    raise "No Github configuration" unless github_conf
    raise "No Gihut access token" unless github_conf['token']

    @github = Octokit::Client.new access_token: github_conf['token']
    @repositories = github_conf['repos'].merge(github_conf['repositories']).map do |n, conf|
      [n, Repository.new(conf)]
    end.to_h

    slack_conf = conf['slack']
    raise "No SLACK configuration provided" unless slack_conf
    raise "No SLACK access token found" unless slack_conf['token']

    @slack = Slack::Client.new token: slack_conf['token']
    @channel = slack_conf['channel']
  end

  class Repository

    attr_reader :id, :approval, :commiters

    def initialize(conf)
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

  end

end