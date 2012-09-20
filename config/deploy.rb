set :branch, "v0"
set :application, "scraperbot"
set :keep_releases, 3
set :server_name,  "192.168.1.53"
set :repository, "d:///referentiel/dev/#{application}/.git"
set :deploy_to, "/home/eric/www/#{application}"
set :scm, "git"
set :deploy_via, :copy
set :user, "eric"
set :password, "Brembo01"
set :copy_compression, :zip
default_run_options[:pty] = true
set :use_sudo, false

role :app, server_name

after "deploy:setup", "customizing:setup"
after "deploy:check", "customizing:check"
#after "deploy:update", "customizing:update"
after "deploy:restart", "customizing:restart"

  namespace :customizing do
      desc "After Check"
      task :check, :roles => :app do
        #customisable par gem, repertoire et composant locaux, exemple / depend :remote, :gem, "tzinfo", ">=0.3.3" depend :local, :command, "svn"  depend :remote, :directory, "/u/depot/files"
        depend :remote, :gem, "eventmachine"
        depend :remote, :gem, "em-http-request"
        depend :remote, :gem, "domainatrix"
        depend :remote, :gem, 'nokogiri'
        depend :remote, :gem, 'json'
        depend :remote, :gem, 'multi_json'
        end
      desc "After Update"
      task :update, :roles => :app  do
          run "echo \"bundle gems\""
          run "cd #{deploy_to}/current && LC_ALL='en_US.UTF-8' bundle install --without development --deployment"
      end
      desc "After Setup"
      task :setup, :roles =>  :app  do

      end
      desc "After Restart"
      task :restart, :roles =>  :app  do

      end
  end



  namespace :deploy do
        desc "RAZ"
    task :raz, :roles => :app do
      run "mysql --user=root --password=#{password} -e \"DROP DATABASE IF EXISTS #{db_name}\""
      run "rm -R #{deploy_to}/releases/ && mkdir #{deploy_to}/releases"
      run "rm -R #{deploy_to}/shared/"
    end




    task :bundle, :roles => :app do
      run "cd #{deploy_to}/current && LC_ALL='en_US.UTF-8' bundle install --without development --deployment"
    end
    desc "Start Application"
    task :start, :roles => :app do
      run "touch #{current_release}/tmp/restart.txt"
    end

    desc "Stop Application"
    task :stop, :roles => :app do
    end

    desc "Restart Application #{current_release}"
    task :restart, :roles => :app do
      run "touch #{current_release}/tmp/restart.txt"
    end

    desc "first deploy"
    task :first, :roles => :app do
        desc "RAZ"
        raz
        desc "Setup"
        setup
        desc "Check"
        check
        desc "Create DataBase"
        createdb
        desc "Update"
        update
        desc "Load DataBase"
        loaddb
        desc "Start"
        start
    end

    desc "next deploy with migration"
    task :next, :roles => :app do
      desc "Update"
      update
      desc "Migrate"
      migrate
      desc "Restart"
      restart
    end


  end