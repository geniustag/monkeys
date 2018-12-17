# config valid only for current version of Capistrano
# lock "3.8.0"

set :application, "dapp"
set :repo_url, "git@github.com:geniustag/monkeys.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, "config/database.yml" #, "config/settings.yml"

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "public/uploads", "public/apps"

set :bundle_without, %w{development test}.join(' ')
set :assets_roles, [:assets]

set :rvm_ruby_string, 'rvm use ruby-2.3.0'
# set :default_env, { path: "/opt/ruby/bin:$PATH" }
# set :default_env, {
#   "PATH" =>"/home/deploy/.rvm/rubies/ruby-2.3.0/bin:$PATH",
#   "GEM_HOME" => "/home/deploy/.rvm/gems"
# }

set :default_shell, '/bin/bash -l'

# Default value for keep_releases is 5
# set :keep_releases, 5
#
namespace :deploy do

  desc 'migrate'
  task :migrate do
    on roles(:db), in: :sequence, wait: 5 do
      within release_path do    
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :'rake db:migrate'
        end 
      end 
    end
  end

  task :assets_compile do
    on roles(:app), in: :sequence, wait: 5 do
      within release_path do    
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :'rake assets:precompile'
        end 
      end 
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  desc 'Restart application'
  task :restart_nginx do
    on roles(:app), in: :sequence, wait: 5 do
      within release_path do    
        with rails_env: fetch(:rails_env) do
          execute "kill `ps -ef |grep nginx |grep -v grep |awk '{print $2}'`" rescue nil 
          execute :sudo, '/opt/nginx/sbin/nginx'
        end
      end
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
    end
  end

  after :publishing, :restart
  before :publishing, :migrate
  before :publishing, :assets_compile
end

