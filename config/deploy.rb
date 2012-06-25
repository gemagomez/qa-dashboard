require "bundler/capistrano"

set :application, "QA Dashboard"

set :scm, :none
set :repository, "."
set :deploy_via, :copy
set :copy_compression, :gzip
set :use_sudo, false
set :host, "alexhornung.com"
set :user, "gema"

ssh_options[:port] = 22
default_run_options[:pty] = true

role :web, host                          # Your HTTP server, Apache/etc
role :app, host                          # This may be the same as your `Web` server
role :db,  host, :primary => true        # This is where Rails migrations will run

set :deploy_to, "/home/gema/qa-dashboard"

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end

#task :production do
#  after("deploy", "configuration")
#end

after :deploy, :configuration

task :configuration do
  run "rm /home/gema/qa-dashboard/current/config/database.yml"
  run "rm /home/gema/qa-dashboard/current/config/config.yml"
  run "ln -s /home/gema/dash-config/database.yml /home/gema/qa-dashboard/current/config/database.yml"
  run "ln -s /home/gema/dash-config/config.yml /home/gema/qa-dashboard/current/config/config.yml"
  restart
end

task :restart do
  run "#{sudo} /etc/init.d/unicorn-dashboard restart"
end

task :db_reset do
  run "cd #{deploy_to}/current && bundle exec rake db:migrate VERSION=0"
  run "cd #{deploy_to}/current && bundle exec rake db:migrate"
end

task :jenkins_pull do
  run "cd #{deploy_to}/current && bundle exec rake jenkins:pull"
end

