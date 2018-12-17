
set :deploy_to, "/home/deploy/projects/dapp"
set :branch, "dev"

server "18.218.224.140", user: "deploy", roles: %w{app web db}
