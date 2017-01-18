module Parse
  # Parses information about Heroku releases and GitHub deployment info
  class Releases
    attr_reader :releases, :deploys

    def initialize(releases, deploys)
      @releases = releases
      @deploys = deploys
    end

    def markdown
      releases.map do |release|
        Release.new(release, GitHubRefs.new(deploys)).row_text
      end.join("\n")
    end
  end

  # Generates a hash of shas with corresponding refs
  class GitHubRefs
    attr_reader :deploy_list

    def initialize(deploy_list)
      @deploy_list = deploy_list
    end

    def by_sha(sha)
      sha_and_ref_hash[sha]
    end

    def sha_and_ref_hash
      @sha_and_ref_hash ||=
        deploy_list.each_with_object(Hash.new(0)) do |deploy, hash|
          sha = deploy["sha"]
          shortened_sha = sha[0..6]
          ref = deploy["ref"]
          ref = shortened_sha if sha == ref
          hash[shortened_sha] = ref
        end
    end
  end

  # Returns information about a single release
  class Release
    include ActionView::Helpers::DateHelper
    attr_reader :release_info, :github_refs

    def initialize(release_info, github_refs)
      @release_info = release_info
      @github_refs = github_refs
    end

    def row_text
      "v#{version} - #{description} - " \
        "#{optional_branch_link}" \
          "#{email} - " \
            "#{created_at}"
    end

    def optional_branch_link
      return unless ref
      "<https://github.com/heroku/#{repo_name}/tree/#{ref}|#{ref}> - "
    end

    def repo_name
      "reponame"
    end

    def version
      release_info["version"]
    end

    def email
      release_info["user"]["email"]
    end

    def created_at
      time_ago_in_words(release_info["created_at"])
    end

    def sha
      sha = description.gsub("Deploy ", "")
      sha =~ /\A\h{7,40}\z/ ? sha[0..6] : nil
    end

    def description
      release_info["description"]
    end

    def ref
      return unless sha
      github_refs.by_sha(sha)
    end
  end
end
