require 'rubygems'
require 'eventmachine'
require 'json'
require 'json/ext'
require 'digest/sha2'
require File.dirname(__FILE__) + '/../lib/logging'
require 'logger'
require 'net/ftp'
require "ruby-progressbar"
require 'yaml'
require File.dirname(__FILE__) + '/../lib/building_visits'
require File.dirname(__FILE__) + '/../lib/building_inputs'
require File.dirname(__FILE__) + '/../lib/building_objectives'
require File.dirname(__FILE__) + '/../lib/common'
require File.dirname(__FILE__) + '/../model/task'
require File.dirname(__FILE__) + '/../model/objective'
require File.dirname(__FILE__) + '/../model/website'
module LoadServer
  INPUT = File.dirname(__FILE__) + "/../input/"
  TMP = File.dirname(__FILE__) + "/../tmp/"

  @@conditions_start = Start_conditions.new()

  def initialize()
    w = self
    @execute_task = EM.spawn { |data| w.execute_task(data) }
  end

  def receive_data(param)
    #TODO multithreader ou spawner les traitements du load server si le besoin est averé
    #TODO gérer la cohérence des dates de building
    #@execute_task.notify JSON.parse param
    Common.information ("data receive : #{param}")
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
        if $envir == "development" or
            ($envir == "production" and @@conditions_start.execute?(task))
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
        business = data["data"]
        count_visit = business["count_visits"] unless business["count_visits"].nil?
        Common.alert("Choosing_landing_pages is not start because count_visit is not define #{count_visit}", __LINE__) if business["count_visits"].nil?
        direct_medium_percent = business["direct_medium_percent"] unless business["direct_medium_percent"].nil?
        Common.alert("Choosing_landing_pages is not start because direct_medium_percent is not define #{direct_medium_percent}", __LINE__) if business["direct_medium_percent"].nil?
        organic_medium_percent = business["organic_medium_percent"] unless business["organic_medium_percent"].nil?
        Common.alert("Choosing_landing_pages is not start because  organic_medium_percent is not define #{organic_medium_percent}", __LINE__) if business["organic_medium_percent"].nil?
        referral_medium_percent = business["referral_medium_percent"] unless business["referral_medium_percent"].nil?
        Common.alert("Choosing_landing_pages is not start because  referral_medium_percent is not define #{referral_medium_percent}", __LINE__) if business["referral_medium_percent"].nil?
        Building_inputs.Choosing_landing_pages(label, date_building,
                                               direct_medium_percent.to_i,
                                               organic_medium_percent.to_i,
                                               referral_medium_percent.to_i,
                                               count_visit.to_i) if !count_visit.nil? and
            !direct_medium_percent.nil? and
            !organic_medium_percent.nil? and
            !referral_medium_percent.nil?
      when "Choosing_device_platform"
        label = data["label"]
        date_building = data["date_building"]
        business = data["data"]
        count_visit = business["count_visits"] unless business["count_visits"].nil?
        Common.alert("Choosing_landing_pages is not start because count_visit is not define #{count_visit}", __LINE__) if business["count_visits"].nil?
        Building_inputs.Choosing_device_platform(label, date_building, count_visit.to_i) unless count_visit.nil?
      when "Building_visits"
        label = data["label"]
        date_building = data["date_building"]
        #task = Task_building_visits.new(label)
        #@@conditions_start.add(task)
        #@@conditions_start.decrement(task)
        #if $envir == "development" or ($envir == "production" and @@conditions_start.execute?(task))

        business = data["data"]
        count_visit = business["count_visits"] unless business["count_visits"].nil?
        Common.alert("Choosing_landing_pages is not start because count_visit is not define #{count_visit}", __LINE__) if business["count_visits"].nil?
        visit_bounce_rate = business["visit_bounce_rate"] unless business["visit_bounce_rate"].nil?
        Common.alert("Choosing_landing_pages is not start because visit_bounce_rate is not define #{visit_bounce_rate}", __LINE__) if business["visit_bounce_rate"].nil?
        page_views_per_visit = business["page_views_per_visit"] unless business["page_views_per_visit"].nil?
        Common.alert("Choosing_landing_pages is not start because page_views_per_visit is not define #{page_views_per_visit}", __LINE__) if business["page_views_per_visit"].nil?
        avg_time_on_site = business["avg_time_on_site"] unless business["avg_time_on_site"].nil?
        Common.alert("Choosing_landing_pages is not start because avg_time_on_site is not define #{avg_time_on_site}", __LINE__) if business["avg_time_on_site"].nil?
        min_durations = business["min_durations"] unless business["min_durations"].nil?
        Common.alert("Choosing_landing_pages is not start because min_durations is not define #{min_durations}", __LINE__) if business["min_durations"].nil?
        min_pages = business["min_pages"] unless business["min_pages"].nil?
        Common.alert("Choosing_landing_pages is not start because min_pages is not define #{min_pages}", __LINE__) if business["min_pages"].nil?
        hourly_distribution = business["hourly_distribution"] unless business["hourly_distribution"].nil?
        Common.alert("Choosing_landing_pages is not start because hourly_distribution is not define #{hourly_distribution}", __LINE__) if business["hourly_distribution"].nil?
        return_visitor_rate = business["return_visitor_rate"] unless business["return_visitor_rate"].nil?
        Common.alert("Choosing_landing_pages is not start because return_visitor_rate is not define #{return_visitor_rate}", __LINE__) if business["return_visitor_rate"].nil?
        account_ga = business["account_ga"] unless business["account_ga"].nil?
        Common.alert("Choosing_landing_pages is not start because account_ga is not define #{account_ga}", __LINE__) if business["account_ga"].nil?

        objective_file = File.open(Common.id_file(TMP, "objective", label, date_building, nil, "json"), "w:UTF-8")
        objective_file.write(business.to_json)
        objective_file.close
        Building_visits.Building_visits(label, date_building,
                                        count_visit.to_i,
                                        visit_bounce_rate.to_f,
                                        page_views_per_visit.to_f,
                                        avg_time_on_site.to_f,
                                        min_durations.to_i,
                                        min_pages.to_i) if !count_visit.nil? and !visit_bounce_rate.nil? and !page_views_per_visit.nil? and !avg_time_on_site.nil? and !min_durations.nil? and !min_pages.nil?

      #  @@conditions_start.delete(task)
      #end

      when "Building_planification"
        label = data["label"]
        date_building = data["date_building"]
        objective = JSON.parse(File.read(Common.id_file(TMP, "objective", label, date_building, nil, "json")))
        count_visit =objective["count_visits"] unless objective["count_visits"].nil?
        Common.alert("Building_planification is not start because count_visit is not define", __LINE__) if objective["count_visits"].nil?
        hourly_distribution = objective["hourly_distribution"] unless objective["count_visits"].nil?
        Common.alert("Building_planification is not start because count_visit is not define", __LINE__) if objective["hourly_distribution"].nil?
        Building_visits.Building_planification(label, date_building,
                                               hourly_distribution,
                                               count_visit.to_i) if !count_visit.nil? and !hourly_distribution.nil?


      when "Extending_visits"
        label = data["label"]
        date_building = data["date_building"]
        objective_id_file = Common.id_file(TMP, "objective", label, date_building, nil, "json")

        objective = JSON.parse(File.read(objective_id_file))
        count_visit =objective["count_visits"] unless objective["count_visits"].nil?
        Common.alert("Extending_visits is not start because count_visit is not define", __LINE__) if objective["count_visits"].nil?
        return_visitor_rate = objective["return_visitor_rate"] unless objective["return_visitor_rate"].nil?
        Common.alert("Extending_visits is not start because return_visitor_rate is not define", __LINE__) if objective["return_visitor_rate"].nil?
        account_ga = objective["account_ga"] unless objective["account_ga"].nil?
        Common.alert("Extending_visits is not start because account_ga is not define", __LINE__) if objective["account_ga"].nil?

        begin
           File.delete(objective_id_file)
        rescue Exception => e
           Common.warn("suppress of file #{objective_id_file} failed : #{e.message}")
        end
        Building_visits.Extending_visits(label, date_building,
                                         count_visit.to_i,
                                         account_ga,
                                         return_visitor_rate.to_f) if !account_ga.nil? and !count_visit.nil? and !return_visitor_rate.nil?

      when "Publishing_visits"
        #TODO publishing visits ne doit pas être déclencher par le extending_visits mais par le Calendar
        #TODO le publishing_visits doit etre réalisé par heure et pas par jour entier
        label = data["label"]
        date_building = data["date_building"]
        Building_visits.Publishing_visits(label, date_building)

      when "Building_objectives"
        label = data["label"]
        date_building = data["date_building"]
        business = data["data"]
        change_count_visits_percent = business["change_count_visits_percent"] unless business["change_count_visits_percent"].nil?
        Common.alert("Building_objectives is not start because change_count_visits_percent is not define", __LINE__) if business["change_count_visits_percent"].nil?
        change_bounce_visits_percent =business["change_bounce_visits_percent"] unless business["change_bounce_visits_percent"].nil?
        Common.alert("Building_objectives is not start because change_bounce_visits_percent is not define", __LINE__) if business["change_bounce_visits_percent"].nil?
        direct_medium_percent =business["direct_medium_percent"] unless business["direct_medium_percent"].nil?
        Common.alert("Building_objectives is not start because direct_medium_percent is not define", __LINE__) if business["direct_medium_percent"].nil?
        organic_medium_percent = business["organic_medium_percent"] unless business["organic_medium_percent"].nil?
        Common.alert("Building_objectives is not start because organic_medium_percent is not define", __LINE__) if business["organic_medium_percent"].nil?
        referral_medium_percent = business["referral_medium_percent"] unless business["referral_medium_percent"].nil?
        Common.alert("Building_objectives is not start because referral_medium_percent is not define", __LINE__) if business["referral_medium_percent"].nil?
        website_id = business["website_id"] unless business["website_id"].nil?
        Common.alert("Building_objectives is not start because website_id is not define", __LINE__) if business["website_id"].nil?
        policy_id = business["policy_id"] unless business["policy_id"].nil?
        Common.alert("Building_objectives is not start because policy_id is not define", __LINE__) if business["policy_id"].nil?
        account_ga = business["account_ga"] unless business["account_ga"].nil?
        Common.alert("Building_objectives is not start because account_ga is not define", __LINE__) if business["account_ga"].nil?

        Building_objectives.Publishing(label, date_building,
                                       change_count_visits_percent.to_i,
                                       change_bounce_visits_percent.to_i,
                                       direct_medium_percent.to_i,
                                       organic_medium_percent.to_i,
                                       referral_medium_percent.to_i,
                                       policy_id,
                                       website_id,
                                       account_ga) if !change_count_visits_percent.nil? and
            !change_bounce_visits_percent.nil? and
            !direct_medium_percent.nil? and
            !organic_medium_percent.nil? and
            !referral_medium_percent.nil? and
            !website_id.nil? and
            !policy_id.nil? and
            !account_ga.nil?
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
PARAMETERS = File.dirname(__FILE__) + "/../parameter/" + File.basename(__FILE__, ".rb") + ".yml"
#ftp_server et load server sont sur la même machine en raison du repertoire de partagé des fichiers
# load_server le rempli, et ftp_server le publie et le vide.
scraper_servers_ip = "localhost" #liste de tous les scraper_server separer par une virgule
listening_port = 9002 # port d'ecoute du load_server
scraper_server_port = 9003 # port d'ecoute du scraper_server
$authentification_server_port = 9001
$authentification_server_ip = "localhost"
$statupbot_server_ip = "localhost"
$statupbot_server_port = 9006
$statupweb_server_ip="localhost"
$statupweb_server_port=3000
$calendar_server_port=9104

$envir = "production"

#--------------------------------------------------------------------------------------------------------------------
# INPUT
#--------------------------------------------------------------------------------------------------------------------
ARGV.each { |arg|
  $envir = arg.split("=")[1] if arg.split("=")[0] == "--envir"
} if ARGV.size > 0

begin
  params = YAML::load(File.open(PARAMETERS), "r:UTF-8")
  listening_port = params[$envir]["listening_port"] unless params[$envir]["listening_port"].nil?
  scraper_servers_ip = params[$envir]["scraper_servers_ip"] unless params[$envir]["scraper_servers_ip"].nil?
  scraper_server_port = params[$envir]["scraper_server_port"] unless params[$envir]["scraper_server_port"].nil?
  $authentification_server_ip = params[$envir]["authentification_server_ip"] unless params[$envir]["authentification_server_ip"].nil?
  $authentification_server_port = params[$envir]["authentification_server_port"] unless params[$envir]["authentification_server_port"].nil?
  $statupbot_server_ip = params[$envir]["statupbot_server_ip"] unless params[$envir]["statupbot_server_ip"].nil?
  $statupbot_server_port = params[$envir]["statupbot_server_port"] unless params[$envir]["statupbot_server_port"].nil?
  $statupweb_server_ip = params[$envir]["statupweb_server_ip"] unless params[$envir]["statupweb_server_ip"].nil?
  $statupweb_server_port = params[$envir]["statupweb_server_port"] unless params[$envir]["statupweb_server_port"].nil?
  $calendar_server_port = params[$envir]["calendar_server_port"] unless params[$envir]["calendar_server_port"].nil?
rescue Exception => e
  p e.message
  Logging.send($log_file, Logger::INFO, "parameters file #{PARAMETERS} is not found")
end

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
      data = {"who" => "load server", "cmd" => "send_me_all_files"}
      Common.send_data_to(scraper_server_ip, scraper_server_port, data)
      Common.information("getting all scrapping files from scraper server #{scraper_server_ip}:#{scraper_server_port}")
    rescue Exception => e
      Common.alert("getting all scrapping files from scraper server #{scraper_server_ip}:#{scraper_server_port} failed", __LINE__)
    end
  }
}
Logging.send($log_file, Logger::INFO, "load server stopped")

#--------------------------------------------------------------------------------------------------------------------
# END
#--------------------------------------------------------------------------------------------------------------------
