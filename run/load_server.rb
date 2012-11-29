require 'rubygems'
require 'eventmachine'
require 'json'
require 'json/ext'
require 'digest/sha2'
require File.dirname(__FILE__) + '/../lib/logging'
require 'logger'
require 'net/ftp'
require "ruby-progressbar"
require File.dirname(__FILE__) + '/../lib/building_visits'
require File.dirname(__FILE__) + '/../lib/building_inputs'


module LoadServer
  INPUT = File.dirname(__FILE__) + "/../input/"
  #TODO supprimer la variable globale COUNT_VISIT
  COUNT_VISIT = 1000
  #TODO remplacer la variable d'instance @@log_file par une constante
  @@log_file

  # definition des conditions d'exécution des taches
  # à chaque tache est associé un nombre d'operation qui doit être réalisée
  @@conditions_start = {"Building_device_platform" => 2, #TASK_CHOOSING_DEVICE_PLATFORME, TASK_CHOOSING_LANDING_PAGES, CALENDAR
                        "Building_visits" => 3} #TASK_CHOOSING_DEVICE_PLATFORME, TASK_CHOOSING_LANDING_PAGES, CALENDAR



  def receive_data param
    #TODO multithreader ou spawner les traitements du load server
    data = JSON.parse param
    who = data["who"]
    port, ip = Socket.unpack_sockaddr_in(get_peername)
    Logging.send($log_file, Logger::DEBUG, "data receive : #{data}")
    case data["cmd"]
      when "file"
        label = data["label"]
        date = data["date_scraping"]
        type_file = data["type_file"]
        id_file = data["id_file"]
        last_volume = data["last_volume"]
        user = data["user"]
        pwd = data["pwd"]
        host_ftp_server = data["where"]
        get_file(id_file, host_ftp_server, user, pwd)
        case type_file
          when "website"
            execute_next_step("Building_matrix_and_pages", label, date) if last_volume
          when "Traffic_source_landing_page"
            execute_next_step("Building_landing_pages", label, date) if last_volume
          when "Device_platform_plugin"
            execute_next_step("Building_device_platform", label, date) if last_volume
          when "Device_platform_resolution"
            execute_next_step("Building_device_platform", label, date) if last_volume
          else
            Logging.send($log_file, Logger::DEBUG, "type file unknown : #{type_file} for #{id_file}")
        end
        close_connection

      when "Building_matrix_and_pages"
        label = data["label"]
        date_building = data["date_building"]
        Building_inputs.Building_matrix_and_pages(label, date_building)

      when "Building_landing_pages"
        label = data["label"]
        date_building = data["date_building"]
        Building_inputs.Building_landing_pages(label, date_building)

      when "Building_device_platform"

        #TODO  valider le déclenchement de cette tache en dev et prod (TASK_CHOOSING_DEVICE_PLATFORME, TASK_CHOOSING_LANDING_PAGES, CALENDAR)
        label = data["label"]
        date_building = data["date_building"]
        @@conditions_start["Building_device_platform"] -=1
        if $envir == "dev" or ($envir == "prod" and @@conditions_start["Building_device_platform"] == 0)
          Building_inputs.Building_device_platform(label, date_building)
          #TODO valider la reinitialisation des conditions de demarrage
          @@conditions_start["Building_device_platform"] = 2
        end

      when "Choosing_landing_pages"

        label = data["label"]
        date_building = data["date_building"]
        direct_medium_percent = 60 # sera calculé en fonction des objectif
        organic_medium_percent = 20 # sera calculé en fonction des objectif
        referral_medium_percent = 20 # sera calculé en fonction des objectif
        count_visit = COUNT_VISIT # sera calculé en fonction des objectif
        Building_inputs.Choosing_landing_pages(label, date_building,
                                               direct_medium_percent,
                                               organic_medium_percent,
                                               referral_medium_percent,
                                               count_visit)
      when "Choosing_device_platform"
        #TODO: selectionner (count_visit) de l'objectif du jour dans la base de données
        #TODO faire une requete rest vers le model et recuperer du json
        label = data["label"]
        date_building = data["date_building"]
        count_visit = COUNT_VISIT
        Building_inputs.Choosing_device_platform(label, date_building, count_visit)

      when "Building_visits"
        #TODO: selectionner (visit_bounce_rate, count_visit, page_views_per_visit, avg_time_on_site) de l'objectif du jour dans la base de données
        #TODO faire une requete rest vers le model et recuperer du json
        #TODO  valider le déclenchement de cette tache en dev et prod (TASK_CHOOSING_DEVICE_PLATFORME, TASK_CHOOSING_LANDING_PAGES, CALENDAR)
        label = data["label"]
        date_building = data["date_building"]
        # seront fournis par l'objectif du jour
        count_visit = COUNT_VISIT
        visit_bounce_rate = 60
        page_views_per_visit = 2
        avg_time_on_site = 120
        min_durations = 1
        min_pages = 2
        @@conditions_start["Building_visits"] -=1
        if $envir == "dev" or ($envir == "prod" and @@conditions_start["Building_visits"] == 0)
          Building_visits.Building_visits(label, date_building,
                                          count_visit,
                                          visit_bounce_rate,
                                          page_views_per_visit,
                                          avg_time_on_site,
                                          min_durations,
                                          min_pages)
          #TODO valider la reinitialisation des conditions de demarrage
          @@conditions_start["Building_visits"] = 3
        end

      when "Building_planification"
        label = data["label"]
        date_building = data["date_building"]
        # seront fournis par l'objectif du jour
        #TODO selectionner la planification du jour dans la base de données
        #TODO faire une requete rest vers le model et recuperer du json
        hourly_distribution = "0;0;0;1;2;3;3.5;3.5;3;2;1;0.5;1;2;3;6;8;10;11;12;12;11.5;2;2"
        count_visit = COUNT_VISIT
        Building_visits.Building_planification(label, date_building,
                                               hourly_distribution,
                                               count_visit)

      when "Extending_visits"
        #TODO: selectionner (account_ga, count_visit, return_visitor_rate) de l'objectif du jour dans la base de données
        #TODO faire une requete rest vers le model et recuperer du json
        label = data["label"]
        date_building = data["date_building"]
        # seront fournis par l'objectif du jour
        count_visit = COUNT_VISIT
        account_ga = "UA-XXXXXX"
        return_visitor_rate = 40
        Building_visits.Extending_visits(label, date_building,
                                         count_visit,
                                         account_ga,
                                         return_visitor_rate)

      when "Publishing_visits"
        label = data["label"]
        date_building = data["date_building"]
        Building_visits.Publishing_visits(label, date_building)

      when "Pushing_visits_file"

      when "exit"
        close_connection
        EventMachine.stop
      else
        Logging.send($log_file, Logger::ERROR, "unknown action : #{data["cmd"]}")
    end
  end

  def unbind
  end

  def get_file(id_file, host_ftp_server, user, pwd)
    begin
      ftp = Net::FTP.new(host_ftp_server)
      ftp.login(user, pwd)
      ftp.gettextfile(id_file, INPUT + id_file)
      ftp.delete(id_file)
      ftp.close

      Logging.send($log_file, Logger::INFO, "download file, #{id_file}to #{INPUT + id_file}")
    rescue Exception => e
      Logging.send($log_file, Logger::FATAL, "download file, #{id_file} failed #{e.message}")
    end
  end


  def execute_next_step(cmd, label, date)
    s = TCPSocket.new 'localhost', $listening_port
    s.puts JSON.generate({"cmd" => cmd, "label" => label, "date_building" => date})
    s.close
  end

  def information(msg)
    Logging.send($log_file, Logger::INFO, msg)
    p "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} => #{msg}"
  end
end


#--------------------------------------------------------------------------------------------------------------------
# INIT
#--------------------------------------------------------------------------------------------------------------------
$log_file = File.dirname(__FILE__) + "/../log/" + File.basename(__FILE__, ".rb") + ".log"
#ftp_server et scraper server sont sur la même machine en raison du repertoire de partagé des fichiers
# scraper_server le rempli, et ftp_server le publie et le vide.
scraper_servers_ip = ["localhost"] #liste de tous les scraper_server separer par une virgule
listening_port = 9002 # port d'ecoute du load_server
scraper_server_port = 9003 # port d'ecoute du scraper_server
$authentification_server_port = 9001
$authentification_server_ip = "localhost"
$statupbot_server_ip = "localhost"
$statupbot_server_port = 9006

$envir = "prod"

#--------------------------------------------------------------------------------------------------------------------
# INPUT
#--------------------------------------------------------------------------------------------------------------------
ARGV.each { |arg|
  listening_port = arg.split("=")[1] if arg.split("=")[0] == "--port"
  scraper_servers_ip = arg.split("=")[1] if arg.split("=")[0] == "--scraper_servers_ip"
  scraper_server_port = arg.split("=")[1] if arg.split("=")[0] == "--scraper_server_port"
  $authentification_server_ip = arg.split("=")[1] if arg.split("=")[0] == "--authentification_servers_ip"
  $authentification_server_port = arg.split("=")[1] if arg.split("=")[0] == "--authentification_server_port"
  $statupbot_server_ip = arg.split("=")[1] if arg.split("=")[0] == "--statupbot_servers_ip"
  $statupbot_server_port = arg.split("=")[1] if arg.split("=")[0] == "--statupbot_server_port"
  $envir = arg.split("=")[1] if arg.split("=")[0] == "--envir"
  #TODO passer en parametre l'url de l'application rail afin de pourvoir executer les requetes rest de selection de données
} if ARGV.size > 0

Logging.send($log_file, Logger::INFO, "parameters of load server : ")
Logging.send($log_file, Logger::INFO, "listening port : #{listening_port}")
Logging.send($log_file, Logger::INFO, "scraper servers ip : #{scraper_servers_ip}")
Logging.send($log_file, Logger::INFO, "scraper server port : #{scraper_server_port}")
Logging.send($log_file, Logger::INFO, "authentification servers ip : #{$authentification_server_ip}")
Logging.send($log_file, Logger::INFO, "authentification server port : #{$authentification_server_port}")
Logging.send($log_file, Logger::INFO, "statupbot servers ip : #{$statupbot_server_ip}")
Logging.send($log_file, Logger::INFO, "statupbot server port : #{$statupbot_server_port}")
$listening_port = listening_port
# sert à propager le port vers les module appeler par le load _server
#afin qu'il lui demande d'executer des commandes

#--------------------------------------------------------------------------------------------------------------------
# MAIN
#--------------------------------------------------------------------------------------------------------------------

# démarrage du server
EventMachine.run {
  Signal.trap("INT") { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }
  Logging.send($log_file, Logger::INFO, "load server is starting")
  EventMachine.start_server "0.0.0.0", listening_port, LoadServer

  # recuperer les fichiers jamais chargés en base
  scraper_servers_ip.split(",").each { |scraper_server_ip|
    begin
      s = TCPSocket.new scraper_server_ip, scraper_server_port
      s.puts JSON.generate({"who" => "load server", "cmd" => "send_me_all_files"})
      s.close
      p "request to scraper server #{scraper_server_ip}, send me all files !!"
      Logging.send($log_file, Logger::INFO, "request to scraper server #{scraper_server_ip}, send me all files !!")
    rescue Exception => e
      Logging.send($log_file, Logger::FATAL, "request to scraper server #{scraper_server_ip}, to retrieve all files, failed : #{e.message}")
    end
  }
}
Logging.send($log_file, Logger::INFO, "load server stopped")

#--------------------------------------------------------------------------------------------------------------------
# END
#--------------------------------------------------------------------------------------------------------------------
