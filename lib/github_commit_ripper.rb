require 'net/http'
require 'uri'
require 'yaml'
require 'json'

class GitHubCommitRipper

  class << self

    def rip_all_commits(repositories)
      commits = []
      repositories.each_index do |index|
        puts "Repository #{index+1} of #{repositories.size}"
        commits << rip_commits(repositories[index])
      end
      commits.flatten!
      File.open('commits.yml', 'w') do |file|
        file.write(YAML::dump(commits))
      end
    end

    def rip_commits(repository)
      commits = []

      page = 1
      loop do
        puts "Commit page #{page}"
        url = %{http://github.com/api/v2/json/commits/list/#{repository[:user_id]}/#{repository[:repository]}/master/?page=#{page}}
        json = get_json(url)
        break if json == nil
        json = JSON.parse(json)
        if json["commits"] == nil
          puts json
        end
        commits << json["commits"].map { |commit| { :language => repository[:language], :message => commit["message"] } }
        page = page + 1
      end
      commits.flatten
    end

    def get_json(url)
      uri = URI.parse(url)
      json = nil
      while json == nil
        json = Net::HTTP.get(uri)
        json = nil if json =~ /\{"error":\["Rate Limit Exceeded for \d+.\d+.\d+.\d+"\]\}/
        return nil if json =~ /\{"error"=>"Not Found"\}/
        sleep(1) if json == nil
      end
      json
    end

  end

end