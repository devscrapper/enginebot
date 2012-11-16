require 'rubygems'
require 'eventmachine'
require 'json'
require 'json/ext'
require 'digest/sha2'
require File.dirname(__FILE__) + '/../lib/logging'
require 'logger'
require 'net/ftp'

require File.dirname(__FILE__) + '/../lib/building_visits'
require File.dirname(__FILE__) + '/../lib/building_inputs'


module LoadServer

  @@log_file
  # definition des conditions d'exécution des taches
  # à chaque tache est associé un nombre d'operation qui doit être réalisée
  @@conditions_start = { "Building_device_platform" => 1,
                          "Building_visits" => 2}
  def initialize()

  end

  def post_init
  end

  def receive_data param
    #TODO multithreader ou spawn les traitements du load server
    data = JSON.parse param
    who = data["who"]
    port, ip = Socket.unpack_sockaddr_in(get_peername)
    Logging.send($log_file, Logger::DEBUG, "data receive : #{data}")
    case data["cmd"]
      when "file"
        label = data["label"]
        date_scraping = data["date_scraping"]
        type_file = data["type_file"]
        id_file = data["id_file"]
        last_volume = data["last_volume"]
        user = data["user"]
        pwd = data["pwd"]
        host_ftp_server = data["where"]
        get_file(id_file, host_ftp_server, user, pwd)
        case  type_file
          when "website"
            execute_next_step("Building_matrix_and_pages", label, date)
          when "Traffic_source_landing_page"
            execute_next_step("Building_landing_pages", label, date)
          when  "Device_platform_plugin"
            execute_next_step("Building_device_platform", label, date)
          when  "Device_platform_resolution"
            execute_next_step("Building_device_platform", label, date)
          else
            Logging.send($log_file, Logger::DEBUG, "type file unknown : #{type_file} for #{id_file}")
        end
        building_inputs(label, date_scraping) if last_volume
        # load file id_file to DB with spawn
        # ==>>>
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
        #TODO s'assurer que les deux fichiers (Device_platform_plugin, Device_platform_resolution) sont présents sinon alerte
        label = data["label"]
        date_building = data["date_building"]
        if $envir ==  "dev" or ($envir ==  "prod" and @@conditions_start["Building_device_platform"] == 0)
            Building_inputs.Building_device_platform(label, date_building)
          else
            @@conditions_start["Building_device_platform"] -=1
          end

      when "Choosing_landing_pages"
        #TODO: selectionner l'objectif du jour dans la base de données et fournir les propriétés de l'objectif
        label = data["label"]
        date_building = data["date_building"]
        direct_medium_percent = 60 # sera calculé en fonction des objectif
        organic_medium_percent = 20 # sera calculé en fonction des objectif
        referral_medium_percent = 20 # sera calculé en fonction des objectif
        count_visit = 100 # sera calculé en fonction des objectif
        Building_inputs.Choosing_landing_pages(label, date_building,
                                               direct_medium_percent,
                                               organic_medium_percent,
                                               referral_medium_percent,
                                               count_visit)
      when "Choosing_device_platform"
        #TODO: selectionner l'objectif du jour dans la base de données et fournir les propriétés de l'objectif
        label = data["label"]
        date_building = data["date_building"]
        count_visit = 100
        Building_inputs.Choosing_device_platform(label, date_building, count_visit)

      when "Building_visits"
        #TODO: selectionner l'objectif du jour dans la base de données et fournir les propriétés de l'objectif
        #TODO déclencher cette tache ssi on déjà été réalisées les taches : Choosing_device_platform, Choosing_landing_pages
        label = data["label"]
        date_building = data["date_building"]
        # seront fournis par l'objectif du jour
        count_visit = 100
        visit_bounce_rate = 60
        page_views_per_visit = 2
        avg_time_on_site = 120
        min_durations = 1
        min_pages = 2
        if $envir ==  "dev" or ($envir ==  "prod" and @@conditions_start["Building_visits"] == 0)
          Building_visits.Building_visits(label, date_building,
                                          count_visit,
                                          visit_bounce_rate,
                                          page_views_per_visit,
                                          avg_time_on_site,
                                          min_durations,
                                          min_pages)
          else
            @@conditions_start["Building_visits"] -=1
          end

      when "Building_planification"
        label = data["label"]
        date_building = data["date_building"]
        # seront fournis par l'objectif du jour
        hourly_distribution = "0;0;0;1;2;3;3.5;3.5;3;2;1;0.5;1;2;3;6;8;10;11;12;12;11.5;2;2"
        count_visit = 100
        Building_visits.Building_planification(label, date_building,
                                               hourly_distribution,
                                               count_visit)

      when "Extending_visits"
        #TODO: selectionner l'objectif du jour dans la base de données et fournir les propriétés de l'objectif
        label = data["label"]
        date_building = data["date_building"]
        # seront fournis par l'objectif du jour
        count_visit = 100
        account_ga = "UA-XXXXXX"
        return_visitor_rate = 40
        Building_visits.Extending_visits(label, date_building,
                                         count_visit,
                                         account_ga,
                                         return_visitor_rate)

      when "Publishing_visits"
        label = data["label"]
        date_building = data["date_building"]
        # seront fournis par l'objectif du jour

        Building_visits.Publishing_visits(label, date_building)

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
$envir = "prod"

#--------------------------------------------------------------------------------------------------------------------
# INPUT
#--------------------------------------------------------------------------------------------------------------------
ARGV.each { |arg|
  listening_port = arg.split("=")[1] if arg.split("=")[0] == "--port"
  scraper_servers_ip = arg.split("=")[1] if arg.split("=")[0] == "--scraper_servers_ip"
  scraper_server_port = arg.split("=")[1] if arg.split("=")[0] == "--scraper_server_port"
  $envir = arg.split("=")[1] if arg.split("=")[0] == "--envir"
} if ARGV.size > 0

Logging.send($log_file, Logger::INFO, "parameters of load server : ")
Logging.send($log_file, Logger::INFO, "listening port : #{listening_port}")
Logging.send($log_file, Logger::INFO, "scraper servers ip : #{scraper_servers_ip}")
Logging.send($log_file, Logger::INFO, "scraper server port : #{scraper_server_port}")
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
