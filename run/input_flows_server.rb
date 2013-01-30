require 'rubygems'
require 'eventmachine'
require 'json'
require 'json/ext'
require 'logger'
require 'net/ftp'
require 'yaml'
require File.dirname(__FILE__) + '/../lib/common'
require File.dirname(__FILE__) + '/../model/flow'
require File.dirname(__FILE__) + '/../model/communication'

module InputFlowsServer
  include Common

  attr :load_server_port, :ftp_server_ip

  def initialize(load_server_port)
    @load_server_port = load_server_port
  end


  def receive_data param
    debug("data receive : #{param}")
    @ftp_server_ip = Socket.unpack_sockaddr_in(get_peername)[1]
    p @ftp_server_ip
    close_connection
    begin
      #TODO on reste en thread tant que pas effet de bord et pas d'explosion du nombre de thread car plus rapide
      Thread.new { execute_task(YAML::load param) }
    rescue Exception => e
      alert("data receive #{param} : #{e.message}")
    end
  end

  def execute_task(data)
    port_ftp_server = data["port_ftp_server"]
    user = data["user"]
    pwd = data["pwd"]
    type_flow = data["type_flow"]
    basename = data["basename"]
    last_volume = data["last_volume"]
    information ("processing request : type_flow : #{type_flow}")
    #TODO gerer l'archivage de l'ancien fichier
    input_flow = Flow.from_basename(INPUT, basename)
    #le serveur ftp et le scraper server sont FORCEMENT sur la meme machine
    input_flow.get(@ftp_server_ip, port_ftp_server, user, pwd)

    case type_flow
      when "website"
        execute_next_task("Building_matrix_and_pages", input_flow) if last_volume

      when "scraping-traffic-source-landing-page"

        execute_next_task("Building_landing_pages", input_flow) if last_volume

      when "scraping-device-platform-plugin"
        begin
          data = {"cmd" => "Building_device_platform", "date_building" => input_flow.date, "label" => input_flow.label}
          Information.new(data).send_to(@load_server_port)
          information("execute next task Building_device_platform for #{input_flow.basename}")
        rescue Exception => e
          alert("execute next task Building_device_platform for #{input_flow.basename} failed")
        end if last_volume

      when "scraping-device-platform-resolution"
        begin
          data = {"cmd" => "Building_device_platform", "date_building" => input_flow.date, "label" => input_flow.label}
          Information.new(data).send_to(@load_server_port)
          information("execute next task Building_device_platform for #{input_flow.basename}")
        rescue Exception => e
          alert("execute next task Building_device_platform for #{input_flow.basename} failed")
        end if last_volume

      when "scraping-hourly-daily-distribution"
        execute_next_task("Building_hourly_daily_distribution", input_flow) if last_volume

      when "scraping-behaviour"
        execute_next_task("Building_behaviour", input_flow) if last_volume
      else
        alert("type flow : #{type_flow} unknowned for #{input_flow.basename}")
    end
  end

  def execute_next_task(cmd, input_flow)
    begin
      data = {"cmd" => cmd, "input_flow" => input_flow}
      Information.new(data).send_to(@load_server_port)
      information("execute next task #{cmd} for #{input_flow.basename}")
    rescue Exception => e
      alert("execute next task #{cmd} for #{input_flow.basename} failed")
    end
  end
end

#--------------------------------------------------------------------------------------------------------------------
# INIT
#--------------------------------------------------------------------------------------------------------------------
$log_file = File.dirname(__FILE__) + "/../log/" + File.basename(__FILE__, ".rb") + ".log"
PARAMETERS = File.dirname(__FILE__) + "/../parameter/" + File.basename(__FILE__, ".rb") + ".yml"
listening_port = 9105 # port d'ecoute
load_server_port = 9101
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
  load_server_port = params[$envir]["load_server_port"] unless params[$envir]["load_server_port"].nil?
rescue Exception => e
  Common.alert("parameters file #{PARAMETERS} is not found")
end

Common.information("parameters of input flows server : ")
Common.information("listening port : #{listening_port}")
Common.information("load server_port : #{load_server_port}")
Common.information("environement : #{$envir}")
#--------------------------------------------------------------------------------------------------------------------
# MAIN
#--------------------------------------------------------------------------------------------------------------------

# démarrage du server
EventMachine.run {
  Signal.trap("INT") { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }
  Common.information("input flows server is starting")
  EventMachine.start_server "0.0.0.0", listening_port, InputFlowsServer, load_server_port
}
Common.information("input flows server stopped")

#--------------------------------------------------------------------------------------------------------------------
# END
#--------------------------------------------------------------------------------------------------------------------
