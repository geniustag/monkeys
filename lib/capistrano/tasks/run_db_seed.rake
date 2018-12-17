desc 'Run DB Seed'
task :run_db_seed do
  on roles(:db) do
    within current_path do
      with rails_env: fetch(:rails_env) do
        execute :rake, 'db:seed'
      end
    end
  end
end
