# Bundler tasks
require 'bundler/capistrano'

set :application, "Academy"

server "www.iwine.com", :web, :app, :db, primary: true

set :default_environment, {
  'LANG' => 'en_US.UTF-8'
}

set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, "git"
set :repository,  "git@github.com/gxbsst/Academy.git"
set :branch, "master"

if ENV['RAILS_ENV'] =='production'
  set :deploy_to, "/srv/rails/west.iwine.com"
  set :user, "iwine"
else
  set :deploy_to, "/srv/rails/west"
  set :user, "rails"
end
#set :rails_env, :production

#set :branch, "master"
#set :deploy_to, "/srv/rails/production.iwine.com"
#set :branch, "develop"
#set :deploy_to, "/srv/rails/iwine.com"


default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after "deploy", "deploy:cleanup" # keep only the last 5 releases


# Where will it be located on a server?
set :unicorn_conf, "#{deploy_to}/current/config/unicorn.rb"
set :unicorn_pid, "#{deploy_to}/shared/pids/unicorn.pid"

# Unicorn control tasks
namespace :deploy do
  task :restart do
    run "if [ -f #{unicorn_pid} ]; then kill -USR2 `cat #{unicorn_pid}`; else cd #{deploy_to}/current && bundle exec unicorn -c #{unicorn_conf} -E #{rails_env} -D; fi"
  end
  task :start do
    run "cd #{deploy_to}/current && bundle exec unicorn -c #{unicorn_conf} -E #{rails_env} -D"
  end
  task :stop do
    run "if [ -f #{unicorn_pid} ]; then kill -QUIT `cat #{unicorn_pid}`; fi"
  end
end
