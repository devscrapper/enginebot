require 'rubygems' # if you use RubyGems

require 'eventmachine'
require 'json'
require 'json/ext'
require 'logger'
require 'rufus-scheduler'
require 'ice_cube'
require 'yaml'
require File.dirname(__FILE__) + '/../lib/logging'
require File.dirname(__FILE__) + '/../lib/common'
require File.dirname(__FILE__) + '/../model/event.rb'
require File.dirname(__FILE__) + '/../model/events.rb'

module CalendarServer

  attr :events


  def receive_data param
    close_connection
    begin
      #TODO on reste en thread tant que pas effet de bord et pas d'explosion du nombre de thread car plus rapide
     Thread.new{ execute_cmd(JSON.parse param)}
    rescue Exception => e
      Common.warning("data receive #{param} : #{e.message}")
    end
  end

  def execute_cmd(data_receive)
    @events = Events.new($load_server_port)
    begin
      object = data_receive["object"]
      cmd = data_receive["cmd"]
      data_event = data_receive["data"]
      event = nil
      Common.information ("processing request : object : #{object}, cmd : #{cmd}")
      Logging.send($log_file, Logger::DEBUG, "data receive : #{data_event}")
      case object
        when Event.name
          event = Event.new(data_event["key"],
                            data_event["cmd"]) if !data_event["key"].nil? and !data_event["cmd"].nil?
        when Policy.name
          event = Policy.new(data_event).to_event
        when Objective.name
          event = Objective.new(data_event).to_event
        else
          Common.alert("object #{object} is not knowned")
      end
      case cmd
        when Event::EXECUTE_ALL
          if !data_event["time"].nil?
            time = Time._load(data_event["time"])
            Common.information("execute all jobs at time #{time}")
            @events.execute_all_at_time(time)
          else
            Common.alert("execute all jobs at time failed because no time was set")
          end
        when Event::EXECUTE_ONE
          Common.information("execute one event #{event}")
          @events.execute_one(event) if @events.exist?(event)
          Common.information("event #{event} is not exist") unless @events.exist?(event)
        when Event::SAVE
          $sem.synchronize {
            Common.information("save  #{object}   #{event.to_s}")
            if event.is_a?(Array)
              event.each { |e|
                @events.delete(e) if @events.exist?(e)
                @events.add(e)
              }
            else
              @events.delete(event) if @events.exist?(event)
              @events.add(event)
            end

            @events.save
          }
        when Event::DELETE
          #TODO etudier le problème de la suppression d'une policy et de son impact sur la planification construite apres execution du building_objectives
          #TODO premier analyse : la répercution sur les objectives sera réalisée par la suppression de objective dans statupweb par declenchement par callback
          $sem.synchronize {
            Common.information("delete  #{object}   #{event.to_s}")
            @events.delete(event)
            @events.save
          }
        else
          Common.alert("command #{cmd} is not known")
      end
    end
  end
end
                   #--------------------------------------------------------------------------------------------------------------------
                   # INIT
                   #--------------------------------------------------------------------------------------------------------------------
$sem = Mutex.new
$log_file = File.dirname(__FILE__) + "/../log/" + File.basename(__FILE__, ".rb") + ".log"
$data_file = File.dirname(__FILE__) + "/../data/" + File.basename(__FILE__, ".rb") + ".json"
PARAMETERS = File.dirname(__FILE__) + "/../parameter/" + File.basename(__FILE__, ".rb") + ".yml"
listening_port = 9014
$load_server_port = 9101
accepted_ip = "0.0.0.0" #le serveur peut être installé sur un  machine dédiée
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
  $load_server_port = params[$envir]["load_server_port"] unless params[$envir]["load_server_port"].nil?
rescue Exception => e
  p e.message
  Logging.send($log_file, Logger::INFO, "parameters file #{PARAMETERS} is not found")
end

Logging.send($log_file, Logger::INFO, "parameters of calendar server : ")
Logging.send($log_file, Logger::INFO, "listening port : #{listening_port}")
Logging.send($log_file, Logger::INFO, "load_server port : #{$load_server_port}")
#--------------------------------------------------------------------------------------------------------------------
# MAIN
#--------------------------------------------------------------------------------------------------------------------
EventMachine.run {
  Signal.trap("INT") { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }
  Logging.send($log_file, Logger::INFO, "calendar server is starting")

  EventMachine.start_server accepted_ip, listening_port, CalendarServer


  scheduler = Rufus::Scheduler.start_new
  #declenche :
  #toutes les heures de tous les jours de la semaine
  scheduler.cron '0 0 * * * 1-7 Europe/Paris' do
    begin
      now = Time.now      #
      data = {"object" => "Event",
              "cmd" => "execute_all",
              "data" => {"time" => now._dump.force_encoding("UTF-8")}}
      Common.send_data_to("localhost", listening_port, data)
    rescue Exception => e
      Common.alert("execute all cmd at time #{now} failed", __LINE__)
    end

  end
}
Logging.send($log_file, Logger::INFO, "calendar server stopped")


