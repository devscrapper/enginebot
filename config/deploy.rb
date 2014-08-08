#---------------------------------------------------------------------------------------------------------------------
# deploy.rb
# il est utilisé pour :
# installé rvm
# installé ruby
# installé les gem de l'application dans un gemset
# déployé l'application
# arrter uo démarrer l'application
# redemarrer la machine
# ---------------------------------------------------------------------------------------------------------------------
# liste de taches de déploiement
# cap machine:setup : installe les pre requis dans l'environement hebergeur  (rvm, ruby installed)
# cap deploy:setup : realise les adaptations sur l'environnement  (shared dir, creation gemset, install gem)
# cap deploy:update : déploie l'application dans une nouvelle release en mettant à jour les liens symbolic,  paramtrage de fichier de conf, ...
# cap deploy:start/stop/restart : démarrer stop ou redemmarre tous les serveurs de l'application
# cap machine:reboot : redemarre le serveur physique
#----------------------------------------------------------------------------------------------------------------------
# ordre de lancement des commandes deploy : first deploy
# 1 cap machine:setup
# 2 cap deploy:setup
# 3 cap deploy:update
# 4 cap machine:reboot
#----------------------------------------------------------------------------------------------------------------------
# ordre de lancement des commandes deploy : next deploy
# 1 cap deploy:setup
# 2 cap deploy:update    # deploie les sources
# 3 cap deploy:restart     # demarre les serveurs
#----------------------------------------------------------------------------------------------------------------------
#on n'utilise pas bundle pour déployer les gem=> on utilise les gem installés sous ruby : les gems system dans un gemset
#----------------------------------------------------------------------------------------------------------------------

require 'pathname'

#----------------------------------------------------------------------------------------------------------------------
# proprietes de l'application
#----------------------------------------------------------------------------------------------------------------------

set :application, "enginebot" # nom application (github)
set :ftp_server_port, 9102 # port d"ecoute du serveur ftp"
set :shared_children, ["archive",
                  "data",
                  "log",
                  "tmp",
                  "input",
                  "output"] # répertoire partagé entre chaque release
set :server_list, ["authentification_#{application}",
                   "calendar_#{application}",
                   "ftpd_#{application}",
                   "input_flows_#{application}",
                   "tasks_#{application}",
                   "scheduler_#{application}"]
set :log_list, ["authentification_server.deb",
                "calendar_server.deb",
                "input_flows_server.deb",
                "tasks_server.deb",
                "scheduler_server.deb"]

#----------------------------------------------------------------------------------------------------------------------
# param rvm
#----------------------------------------------------------------------------------------------------------------------

require "rvm/capistrano" #  permet aussi d'installer rvm et ruby
require "rvm/capistrano/alias_and_wrapp"
require "rvm/capistrano/gem_install_uninstall"
set :rvm_ruby_string, '1.9.3' # defini la version de ruby a installer
set :rvm_type, :system #RVM installed in /usr/local, multiuser installation
set :rvm_autolibs_flag, "read-only" # more info: rvm help autolibs
set :bundle_dir, '' # on n'utilise pas bundle pour instaler les gem
set :bundle_flags, '--system --quiet' # on n'utilise pas bundle pour instaler les gem
set :rvm_install_with_sudo, true

before 'machine:setup', 'rvm:install_rvm' # install/update RVM
before 'machine:setup', 'rvm:install_ruby' # install Ruby

#----------------------------------------------------------------------------------------------------------------------
# param extraction git
#----------------------------------------------------------------------------------------------------------------------

ENV["path"] += ";d:\\\portableGit\\bin" # acces au git local à la machine qui execute ce script
set :repository, "file:///../referentiel/src/#{application}/.git"
set :scm, "git"
set :copy_dir, "d:\\temp" # reperoitr temporaire de d'extracion des fichiers du git pour les zipper
set :branch, "master" # version à déployer

#----------------------------------------------------------------------------------------------------------------------
# param déploiement vers server cible
#----------------------------------------------------------------------------------------------------------------------

set :keep_releases, 3 # nombre de version conservées
set :server_name, "192.168.1.85" # adresse du server de destination
set :deploy_to, "/usr/local/rvm/wrappers/#{application}" # repertoire de deploiement de l'application
set :deploy_via, :copy # using a local scm repository which cannot be accessed from the remote machine.
set :user, "eric"
set :password, "Brembo01"
default_run_options[:pty] = true
set :use_sudo, true
set :staging, "test"
role :app, server_name

before 'deploy', 'rvm:create_alias'
before 'deploy', 'rvm:create_wrappers'
after "deploy:update", "customize:update"
after "deploy:setup", "customize:setup"
after 'deploy:setup', 'rvm:create_gemset'

#----------------------------------------------------------------------------------------------------------------------
# task list : stage
#----------------------------------------------------------------------------------------------------------------------
namespace :stage do
  task :dev, :roles => :app do
    run "echo 'staging: development' >  #{File.join(current_path, 'parameter', 'environment.yml')}"
  end
  task :testing, :roles => :app do
    run "echo 'staging: test' >  #{File.join(current_path, 'parameter', 'environment.yml')}"
  end
  task :prod, :roles => :app do
    run "echo 'staging: production' >  #{File.join(current_path, 'parameter', 'environment.yml')}"
  end
end

#----------------------------------------------------------------------------------------------------------------------
# task list : log
#----------------------------------------------------------------------------------------------------------------------
namespace :log do
  task :down, :roles => :app do
   capture("ls #{File.join(current_path, 'log', '*.*')}").split(/\r\n/).each{|log_file|
     get log_file, File.join(File.dirname(__FILE__), '..', 'log', File.basename(log_file))
   }
  end

  task :delete, :roles => :app do
    run "rm #{File.join(current_path, 'log', '*')}"
  end

end

#----------------------------------------------------------------------------------------------------------------------
# task list : machine
#----------------------------------------------------------------------------------------------------------------------
namespace :machine do
  task :reboot, :roles => :app do
    run "#{sudo} reboot"
  end
  task :setup, :roles => :app do
    run "rvm alias create default #{rvm_ruby_string}"
  end
end

#----------------------------------------------------------------------------------------------------------------------
# task list : deploy
#----------------------------------------------------------------------------------------------------------------------
namespace :deploy do
  task :start, :roles => :app, :except => {:no_release => true} do
    server_list.each { |server| run "#{sudo} initctl start #{server}" }
  end

  task :stop, :roles => :app, :except => {:no_release => true} do
    server_list.each { |server| run "#{sudo} initctl stop #{server}" }
  end

  task :restart, :roles => :app, :except => {:no_release => true} do
    server_list.each { |server| run "#{sudo} initctl stop #{server}" }
    server_list.each { |server| run "#{sudo} initctl start #{server}" }
  end
end

#----------------------------------------------------------------------------------------------------------------------
# task list : customize :
# setup = creation des repertoires partagés entre releases (data, output, tmp)
# setup = installation des gem dans le gesmset
# update = déploiement de fichier de controle upstart
# update = definition du stage dans lequel s'execute l'application
# update = parametrage du serveur ftp
#----------------------------------------------------------------------------------------------------------------------
namespace :customize do
  task :setup do
    # installation des gem dans le gesmset
    gemlist(Pathname.new(File.join(File.dirname(__FILE__), '..', 'Gemfile')).realpath).each { |parse|
      run_without_rvm("#{path_to_bin_rvm(:with_ruby => rvm_ruby_string_evaluated)} gem query -I #{parse[:name].strip} -v #{parse[:version].strip} ; if [  $? -eq 0 ] ; then #{path_to_bin_rvm(:with_ruby => rvm_ruby_string_evaluated)} gem install #{parse[:name].strip} -v #{parse[:version].strip} -N ; else echo \"gem #{parse[:name].strip} #{parse[:version].strip} already installed\" ; fi")
    }
  end

  task :update do
    # suppression des fichier de controle pour upstart
    server_list.each { |server|
      run "#{sudo} rm --interactive=never -f /etc/init/#{server}.conf"
    }
    # déploiement des fichier de controle pour upstart
    run "#{sudo} cp #{File.join(current_path, 'control', '*')} /etc/init"

    #creation des lien vers les repertoire partagés
    shared_children.each { |dir|
      run "ln -f -s #{File.join(deploy_to, "shared", dir)} #{File.join(current_path, dir)}"
    }

    # definition du type d'environement
    run "echo 'staging: #{staging}' >  #{File.join(current_path, 'parameter', 'environment.yml')}"

    # parametrage du server FTP
    run "rm #{File.join(current_path, 'config', 'config.rb')}"
    config = "require '" + File.join(current_path, 'run', 'driver_em_ftpd.rb') + "'\n"
    config += "driver     FTPDriver\n"
    config += "port #{ftp_server_port}"
    put config, File.join(current_path, 'config', 'config.rb')
  end
end

#----------------------------------------------------------------------------------------------------------------------
# put_sudo
#----------------------------------------------------------------------------------------------------------------------
# permet d'uploader un fichier dans un repertoire pour lequel il faut des droits administrateur ; exemple /etc/init
#----------------------------------------------------------------------------------------------------------------------
def put_sudo(data, to)
  filename = File.basename(to)
  to_directory = File.dirname(to)
  put data, "/tmp/#{filename}"
  run "#{sudo} mv /tmp/#{filename} #{to_directory}"
end

#----------------------------------------------------------------------------------------------------------------------
# gemlist
#----------------------------------------------------------------------------------------------------------------------
# permet de recuperer la liste des gem à partir du Gemfile à installer.
#----------------------------------------------------------------------------------------------------------------------
def gemlist(file)
  gemlist = []
  gemfile = File.open(file)
  catch_gem = true
  gemfile.readlines.each { |line|
    case line
      when /gem (.*)/
        if catch_gem
          gemlist << /gem '(?<name>.*)', '~>(?<version> \d+\.\d+\.\d+)'/.match(line)
        end
      when /.*:development.*/
        catch_gem = false
      when /;*:production.*/
        catch_gem = true
    end
  }
  p gemlist
  gemlist
end
