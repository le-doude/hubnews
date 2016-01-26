class PullRequest

  def initialize(pr_data, github_client = nil)
    @client = github_client
    if pr_data
      @data_source = pr_data
      @data_source.fields.each do |field|
        define_method field do
          @data_source.send(field)
        end
      end
    end
  end

  def issue_comments
    @issue_comments ||= @client.issue_comments(base.repo.full_name, number)
  end

  def issue_comments=(ic_array)
    @issue_comments = ic_array
  end

  def lgtms
    @issue_comments.select { |comment| comment.body? && comment.body.include?("LGTM") }
  end

end