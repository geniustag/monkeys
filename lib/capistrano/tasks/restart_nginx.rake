desc 'Restart Nginx Service'
task :restart_nginx do
  on roles(:web) do
    execute :sudo, '/etc/init.d/nginx restart'
  end
end
