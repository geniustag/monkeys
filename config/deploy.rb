require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rvm'
require 'mina/slack/tasks'

set :repository, 'git@github.com:geniustag/XNodes-admin.git'
set :user, 'deploy'
set :deploy_to, '/home/deploy/projects/xnodes-admin'
domains = %w(18.221.12.158)

def rails_env
  ENV['env']
end

if rails_env == 'dev'
  domains = %w(18.218.137.162)
  set :rails_env, 'dev'
  set :branch, 'master'
elsif rails_env == 'production'
  set :rails_env, 'production'
  set :branch, 'master'
end

set :shared_paths, [
  'config/database.yml',
  'public/uploads',
  'public/apps',
  'tmp',
  'log'
]

task :environment do
  invoke :'rvm:use[2.1.0]'
end

task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]

  queue! %[mkdir -p "#{deploy_to}/shared/tmp"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp"]

  queue! %[touch "#{deploy_to}/shared/config/database.yml"]
end

desc "Deploys the current version to the server."
task deploy: :environment do
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:touch_client_i18n_assets'
    invoke :'rails:assets_precompile'

    to :launch do
      invoke :'passenger:restart'
      invoke :'sidekiq:restart'
    end
  end
end

task mdeploy: :environment do
  domains.each do |domain|
    puts "Deploy with: #{domain}"
    set :domain, domain
    invoke :deploy
  end
end

namespace :sidekiq do
  desc "Restart Sidekiq"
  task :restart do
    queue %{
      echo "-----> Restarting Sidekiq"
      cd #{deploy_to}/current
      #{echo_cmd %[RAILS_ENV=#{rails_env} bundle exec sidekiqctl stop tmp/pids/sidekiq.pid]}
      #{echo_cmd %[RAILS_ENV=#{rails_env} bundle exec sidekiq -C config/sidekiq.yml -d]}
    }
  end
end

namespace :passenger do
  desc "Restart Passenger"
  task :restart do
    queue %{
      echo "-----> Restarting passenger"
      cd #{deploy_to}/current
      #{echo_cmd %[mkdir -p tmp]}
      #{echo_cmd %[touch tmp/restart.txt]}
    }
  end
end

namespace :rails do
  task :touch_client_i18n_assets do
    queue %[
      echo "-----> Touching clint i18n assets"
      #{echo_cmd %[RAILS_ENV=#{rails_env} bundle exec rake deploy:touch_client_i18n_assets]}
    ]
  end
end

