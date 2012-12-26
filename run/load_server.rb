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
require File.dirname(__FILE__) + '/../lib/building_objectives'
require File.dirname(__FILE__) + '/../lib/common'
require File.dirname(__FILE__) + '/../model/task'
require File.dirname(__FILE__) + '/../model/objective'
require File.dirname(__FILE__) + '/../model/website'
module LoadServer
  INPUT = File.dirname(__FILE__) + "/../input/"


  @@conditions_start = Start_conditions.new()

  def initialize()
    w = self
    @execute_task = EM.spawn { |data| w.execute_task(data) }
  end

  def receive_data(param)
    #TODO multithreader ou spawner les traitements du load server si le besoin est averé
    #@execute_task.notify JSON.parse param
    execute_task(JSON.parse param)
  end

  def execute_task(data)
    who = data["who"]
    task = data["cmd"]
    port, ip = Socket.unpack_sockaddr_in(get_peername)
    Logging.send($log_file, Logger::DEBUG, "data receive : #{data}")
    case task
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
            Common.execute_next_task("Building_matrix_and_pages", label, date) if last_volume
          when "Traffic_source_landing_page"
            Common.execute_next_task("Building_landing_pages", label, date) if last_volume
          when "Device_platform_plugin"
            Common.execute_next_task("Building_device_platform", label, date) if last_volume
          when "Device_platform_resolution"
            Common.execute_next_task("Building_device_platform", label, date) if last_volume
          when "Hourly_daily_distribution"
            Common.execute_next_task("Building_hourly_daily_distribution", label, date) if last_volume
          when "Behaviour"
            Common.execute_next_task("Building_behaviour", label, date) if last_volume
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
        label = data["label"]
        date_building = data["date_building"]
        task = Task_building_device_platform.new(label)
        @@conditions_start.add(task)
        @@conditions_start.decrement(task)
        if $envir == "dev" or
            ($envir == "prod" and @@conditions_start.execute?(task))
          Building_inputs.Building_device_platform(label, date_building)
          @@conditions_start.delete(task)
        end

      when "Building_hourly_daily_distribution"
        label = data["label"]
        date_building = data["date_building"]
        Building_inputs.Building_hourly_daily_distribution(label, date_building)

      when "Building_behaviour"
        label = data["label"]
        date_building = data["date_building"]
        Building_inputs.Building_behaviour(label, date_building)

      when "Choosing_landing_pages"
        label = data["label"]
        date_building = data["date_building"]
        #TODO recuperer les data business dans la requete
        count_visit, direct_medium_percent, organic_medium_percent, referral_medium_percent = Objective.new(label, date_building).landing_pages
        Logging.send($log_file, Logger::DEBUG, "Choosing_landing_pages : count_visit = #{count_visit}, \
              direct_medium_percent #{direct_medium_percent} \
              organic_medium_percent #{organic_medium_percent} \
              referral_medium_percent #{referral_medium_percent}")

        if !count_visit.nil? and !direct_medium_percent.nil? and !organic_medium_percent.nil? and !referral_medium_percent.nil?
          Building_inputs.Choosing_landing_pages(label, date_building,
                                                 direct_medium_percent.to_i,
                                                 organic_medium_percent.to_i,
                                                 referral_medium_percent.to_i,
                                                 count_visit.to_i)
        else
          Common.alert("retrieving count_visit, direct_medium_percent, organic_medium_percent, referral_medium_percent for #{label} at #{date_building} is failed")
        end
      when "Choosing_device_platform"
        label = data["label"]
        date_building = data["date_building"]
        #TODO recuperer les data business dans la requete
        count_visit = Objective.new(label, date_building).count_visits
        Logging.send($log_file, Logger::DEBUG, "Choosing_device_platform : count_visit = #{count_visit}")
        Building_inputs.Choosing_device_platform(label, date_building, count_visit.to_i) unless count_visit.nil?
        Common.alert("getting count_visits for #{label} at #{date_building} is failed", __LINE__) if count_visit.nil?

      when "Building_visits"
        label = data["label"]
        date_building = data["date_building"]
        #TODO recuperer les data business dans la requete
        #TODO sauvegarder dans un fichier (label-date_building.json)les données de l'objectif dans TMP
        count_visit, visit_bounce_rate, page_views_per_visit, avg_time_on_site, min_durations, min_pages = Objective.new(label, date_building).behaviour
        Logging.send($log_file, Logger::DEBUG, "Building_visits : count_visit = #{count_visit}, \
              visit_bounce_rate #{visit_bounce_rate} \
              page_views_per_visit #{page_views_per_visit} \
              avg_time_on_site #{avg_time_on_site} \
              min_durations #{min_durations} \
              min_pages #{min_pages}")
        if !count_visit.nil? and !visit_bounce_rate.nil? and !page_views_per_visit.nil? and !avg_time_on_site.nil? and !min_durations.nil? and !min_pages.nil?
          task = Task_building_visits.new(label)
          @@conditions_start.add(task)
          @@conditions_start.decrement(task)
          if $envir == "dev" or ($envir == "prod" and @@conditions_start.execute?(task))
            Building_visits.Building_visits(label, date_building,
                                            count_visit.to_i,
                                            visit_bounce_rate.to_f,
                                            page_views_per_visit.to_f,
                                            avg_time_on_site.to_f,
                                            min_durations.to_i,
                                            min_pages.to_i)
            @@conditions_start.delete(task)
          end
        else
          Common.alert("getting count_visits, visit_bounce_rate, page_views_per_visit, avg_time_on_site, min_durations, min_pages for #{label} at #{date_building} is failed", __LINE__)
        end
      when "Building_planification"
        #TODO recuperer les données de l'objectif à partir du fichier (label-date_building.json)
        label = data["label"]
        date_building = data["date_building"]
        count_visit, hourly_distribution = Objective.new(label, date_building).daily_planification
        Logging.send($log_file, Logger::DEBUG, "Building_planification : count_visit = #{count_visit}, \
            hourly_distribution #{hourly_distribution}")
        if !count_visit.nil? and !hourly_distribution.nil?
          Building_visits.Building_planification(label, date_building,
                                                 hourly_distribution,
                                                 count_visit.to_i)
        else
          Common.alert("getting count_visits, hourly_distribution for #{label} at #{date_building} is failed")
        end
      when "Extending_visits"
        #TODO recuperer les données de l'objectif à partir du fichier (label-date_building.json)
        label = data["label"]
        date_building = data["date_building"]
        account_ga = Website.new(label).account_ga
        Logging.send($log_file, Logger::DEBUG, "Extending_visits : account_ga = #{account_ga}")
        count_visit, return_visitor_rate= Objective.new(label, date_building).return_visitor_rate
        Logging.send($log_file, Logger::DEBUG, "Extending_visits : count_visit = #{count_visit} \
                                                                   return_visitor_rate = #{return_visitor_rate} ")
        if !account_ga.nil? and !count_visit.nil? and !return_visitor_rate.nil?
          Building_visits.Extending_visits(label, date_building,
                                           count_visit.to_i,
                                           account_ga,
                                           return_visitor_rate.to_f)
        else
          Common.alert("getting count_visit, account_ga, return_visitor_rat for #{label} at #{date_building} is failed")
        end

      when "Publishing_visits"
        label = data["label"]
        date_building = data["date_building"]
        Building_visits.Publishing_visits(label, date_building)

      when "Building_objectives"
        label = data["label"]
        date_building = data["date_building"]
        change_count_visits_percent = data["data"]["change_count_visits_percent"]
        change_bounce_visits_percent =data["data"]["change_bounce_visits_percent"]
        direct_medium_percent =data["data"]["direct_medium_percent"]
        organic_medium_percent = data["data"]["organic_medium_percent"]
        referral_medium_percent = data["data"]["referral_medium_percent"]
        website_id = data["data"]["website_id"]
        policy_id = data["data"]["policy_id"]
        account_ga = data["data"]["account_ga"]

        Logging.send($log_file, Logger::DEBUG, "Building_objectives : change_count_visits_percent = #{change_count_visits_percent}, \
                     change_bounce_visits_percent #{change_bounce_visits_percent} \
                     direct_medium_percent #{direct_medium_percent} \
                     organic_medium_percent #{organic_medium_percent} \
                     referral_medium_percent #{referral_medium_percent} \
                      website_id #{website_id} \
                        policy_id #{policy_id} \
                      account_ga #{account_ga}")

        if !change_count_visits_percent.nil? and
            !change_bounce_visits_percent.nil? and
            !direct_medium_percent.nil? and
            !organic_medium_percent.nil? and
            !referral_medium_percent.nil? and
            !website_id.nil? and
            !policy_id.nil? and
            !account_ga.nil?
          task = Task_building_objectives.new(label)
          @@conditions_start.add(task)
          @@conditions_start.decrement(task)
          if $envir == "dev" or ($envir == "prod" and @@conditions_start.execute?(task))
            Building_objectives.Publishing(label, date_building,
                                           change_count_visits_percent.to_i,
                                           change_bounce_visits_percent.to_i,
                                           direct_medium_percent.to_i,
                                           organic_medium_percent.to_i,
                                           referral_medium_percent.to_i,
                                           policy_id,
                                           website_id,
                                           account_ga)
          end
        else
          Common.alert(" getting change_count_visits_percent, change_bounce_visits_percent, direct_medium_percent, organic_medium_percent, referral_medium_percent, website_id, policy_id, account_ga for #{label} at #{date_building} is failed", __LINE__)
        end
      when "exit"
        close_connection
        EventMachine.stop
      else
        Logging.send($log_file, Logger::ERROR, "unknown action : #{task}")
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
$statupweb_server_ip="localhost"
$statupweb_server_port=3000
$calendar_server_port=9104

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
  $statupbot_server_ip = arg.split("=")[1] if arg.split("=")[0] == "--statupbot_servers_ip"
  $statupweb_server_port = arg.split("=")[1] if arg.split("=")[0] == "--statupweb_server_port"
  $statupweb_server_port = arg.split("=")[1] if arg.split("=")[0] == "--statupweb_server_port"
  $calendar_server_port = arg.split("=")[1] if arg.split("=")[0] == "--calendar_server_port"
  $envir = arg.split("=")[1] if arg.split("=")[0] == "--envir"
} if ARGV.size > 0

Logging.send($log_file, Logger::INFO, "parameters of load server : ")
Logging.send($log_file, Logger::INFO, "listening port : #{listening_port}")
Logging.send($log_file, Logger::INFO, "scraper servers ip : #{scraper_servers_ip}")
Logging.send($log_file, Logger::INFO, "scraper server port : #{scraper_server_port}")
Logging.send($log_file, Logger::INFO, "authentification servers ip : #{$authentification_server_ip}")
Logging.send($log_file, Logger::INFO, "authentification server port : #{$authentification_server_port}")
Logging.send($log_file, Logger::INFO, "statupbot servers ip : #{$statupbot_server_ip}")
Logging.send($log_file, Logger::INFO, "statupbot server port : #{$statupbot_server_port}")
Logging.send($log_file, Logger::INFO, "statupweb server ip : #{$statupweb_server_ip}")
Logging.send($log_file, Logger::INFO, "statupweb server port : #{$statupweb_server_port}")
Logging.send($log_file, Logger::INFO, "calendar server port : #{$calendar_server_port}")
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
