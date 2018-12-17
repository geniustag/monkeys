desc 'Restart Application'
task :restart_app do
  on roles(:db) do
    within current_path do
      with rails_env: fetch(:rails_env) do
        execute :touch, 'tmp/restart.txt'
      end
    end
  end
end
