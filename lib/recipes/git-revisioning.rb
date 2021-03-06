set :current_revision do
  capture("head -1 #{current_path}/REVISION", :except => { :no_release => true }).chomp
end

set :revision_file, 'REVISION'

namespace :revision do
  desc "Create a REVISION file containing the SHA of the deployed commit"
  task :set, :except => { :no_release => true } do
    # If for some reason we cannot find the commit sha, then we'll use the branch name
    sha = "origin/#{branch}"
    run "cd #{current_path}; git rev-parse origin/#{branch}" do |channel, stream, data|
      sha = data.strip
    end

    commands = []
    commands << "cd #{current_path}"
    commands << "echo '#{sha}' > #{revision_file}"
    commands << "echo '#{branch}' >> #{revision_file}"
    commands << "echo '#{logged_user}' >> #{revision_file}"
    commands << "echo '#{Time.now}' >> #{revision_file}"
    run commands.join ' && '
  end

  desc "Get info about last deploy"
  task :get do
    keys = %w(SHA Branch Author Date).reverse
    run "cat #{current_path}/#{revision_file}" do |c, s, data|
      data.strip.lines.each do |line|
        puts "#{keys.pop}: #{line.strip}" if keys.any?
      end
    end
  end
end

after 'deploy:update', 'revision:set'
