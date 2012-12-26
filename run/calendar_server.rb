require 'rubygems' # if you use RubyGems

require 'eventmachine'
require 'json'
require 'json/ext'
require 'logger'
require 'rufus-scheduler'
require 'ice_cube'
require File.dirname(__FILE__) + '/../lib/logging'
require File.dirname(__FILE__) + '/../lib/common'
require File.dirname(__FILE__) + '/../model/event.rb'
require File.dirname(__FILE__) + '/../model/events.rb'

module CalendarServer

  attr :events

  def initialize(events)
    @events = events
  end

  def receive_data param
    port, ip = Socket.unpack_sockaddr_in(get_peername)
    Common.information ("data receive : #{param}")
    begin
      data_receive = JSON.parse param
      close_connection
      Logging.send($log_file, Logger::DEBUG, "data receive parsed : #{data_receive}")
      object = data_receive["object"]
      cmd = data_receive["cmd"]
      data_event = data_receive["data"]
      event = nil

      case object
        when Event.name
          event = Event.new(data_event["key"],
                            data_event["cmd"])  if !data_event["key"].nil? and !data_event["cmd"].nil?
        when Policy.name
          event = Policy.new(data_event).to_event
        when Objective.name
          event = Objective.new(data_event).to_event
        else
          Common.alert("object #{object} is not known")
      end
      case cmd
        when Event::EXECUTE_ALL
          Common.information("execute all jobs of the day #{Date.today}")
          @events.execute_all_at_time(Date.parse(data_event["time"])) unless data_event["time"].nil?
          @events.execute_all_at_time if data_event["time"].nil?

        when Event::EXECUTE_ONE
          Common.information("execute one event #{event}")
          @events.execute_one(event)

        when Event::SAVE
          $sem.synchronize {
            Common.information("save  #{object}   #{event.to_s}")
            @events.delete(event) if @events.exist?(event)
            @events.add(event)
            @events.save
          }
        when Event::DELETE
          $sem.synchronize {
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
listening_port = 9014
$load_server_port = 9002
accepted_ip = "0.0.0.0" #le serveur peut être installé sur un  machine dédiée


#--------------------------------------------------------------------------------------------------------------------
# INPUT
#--------------------------------------------------------------------------------------------------------------------
ARGV.each { |arg|
  listening_port = arg.split("=")[1] if arg.split("=")[0] == "--port"
  $load_server_port = arg.split("=")[1] if arg.split("=")[0] == "--load_server_port"
} if ARGV.size > 0


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
  events = Events.new($load_server_port)
  EventMachine.start_server accepted_ip, listening_port, CalendarServer, events


  scheduler = Rufus::Scheduler.start_new
  scheduler.cron '0 15 21 * * 1-7' do #every day of the week at 22:00 (10pm)
    execute_jobs
  end


}
Logging.send($log_file, Logger::INFO, "calendar server stopped")



