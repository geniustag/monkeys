# TODO: continue investigation
namespace :rails do
  desc "Remote console"
  task :console do
    run_interactively "bundle exec rails console #{fetch(:rails_env)}"
  end

  desc "Remote dbconsole"
  task :dbconsole do
    run_interactively "bundle exec rails dbconsole #{fetch(:rails_env)}"
  end
end

def run_interactively(command)
  server = roles(:web)[ARGV[2].to_i]
  exec %Q(ssh #{server.user}@#{server.hostname} -t '#{command}')
end
