require 'rubygems' # if you use RubyGems
require 'eventmachine'
require 'json'
require 'json/ext'
require File.dirname(__FILE__) + '/../lib/logging'
require 'logger'
require 'rufus-scheduler'
require 'ice_cube'
require File.dirname(__FILE__) + '/../model/event.rb'

module CalendarServer

  def receive_data param
    port, ip = Socket.unpack_sockaddr_in(get_peername)
    p "data recu : #{param}"
    begin
      data_receive = JSON.parse param
      p "data parse : #{data_receive}"
      close_connection
      who = data_receive["who"]
      what = data_receive["what"]
      cmd = data_receive["cmd"]

      Logging.send($log_file, Logger::DEBUG, "data receive : #{data_receive}")
      case what
        when "calendar"
          case cmd
            when "execute_jobs"
              p "execute jobs of the day #{Date.today}"
              Logging.send($log_file, Logger::DEBUG, "execute jobs of the day #{Date.today}")
              execute_jobs
            when "execute_one_job"
              p "execute one job #{data_receive["id"]}"
              Logging.send($log_file, Logger::DEBUG, "execute one job #{data_receive["id"]}")
              execute_one_job(data_receive["id"])
            else
              Logging.send($log_file, Logger::ERROR, "unknown action : #{cmd} from  #{ip}:#{port}")
          end
        else
          $sem.synchronize {
            begin
              data_file = File.read($data_file)
              events = JSON.parse(data_file)
              File.delete($data_file)
            rescue Exception => e
              events = Hash.new
            end
            data_file = File.open($data_file, "w")
            events[what] = Array.new if events[what].nil?
            event = Event.new(data_receive)

            if cmd == "save" and event.belongs_to(events[what])
              events[what] = event.delete(events[what])
              events[what] << event.to_json
              Logging.send($log_file, Logger::DEBUG, "update #{what}  #{event.to_json}")
              p "update #{what}   #{event.label}"
            end

            if cmd == "save" and !event.belongs_to(events[what])
              events[what] << event.to_json
              Logging.send($log_file, Logger::DEBUG, "new #{what}  #{event.to_json}")
              p "add #{what}   #{event.label} to repository"
            end

            if cmd == "delete" and event.belongs_to(events[what])
              events[what] = event.delete(events[what])
              Logging.send($log_file, Logger::DEBUG, "delete #{what}  #{event.to_json}")
              p "delete #{what}   #{event.label}"
            end
            data_file.write(JSON.pretty_generate(events))
            data_file.close
          }
      end
    rescue Exception => e
      Logging.send($log_file, Logger::DEBUG, "param : #{param} : #{e.message}")
    end
  end
end

def execute_jobs
  data_file = File.read($data_file)
  events = JSON.parse(data_file)
  events.each_pair { |what, list|
    list.each { |e|
      event = JSON.parse(e)
      schedule =IceCube::Schedule.from_yaml(event["periodicity"])
      Event.new(event).execute($load_server_port) if schedule.occurs_on?(Date.today)
    }
  }
end

def execute_one_job(id)
  data_file = File.read($data_file)
   events = JSON.parse(data_file)
   events.each_pair { |what, list|
     list.each { |e|
       event = JSON.parse(e)
       Event.new(event).execute($load_server_port) if event["id"]   == id
     }
   }
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
  EventMachine.start_server accepted_ip, listening_port, CalendarServer


  scheduler = Rufus::Scheduler.start_new
  scheduler.cron '0 15 21 * * 1-7' do #every day of the week at 22:00 (10pm)
    execute_jobs
  end


}
Logging.send($log_file, Logger::INFO, "calendar server stopped")



