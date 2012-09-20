require 'rubygems'
require 'eventmachine'
require 'json'
require 'json/ext'
require 'digest/sha2'
require File.dirname(__FILE__) + '/../lib/logging'
require 'logger'
require 'net/ftp'


module LoadServer
  INPUT = File.dirname(__FILE__) + "/../input/"
  @@log_file
  attr :host_ftp_server

  def initialize(ftp_server_ip)
    @host_ftp_server = ftp_server_ip
  end

  def post_init
  end

  def receive_data param
    data = JSON.parse param
    who = data["who"]
    port, ip = Socket.unpack_sockaddr_in(get_peername)
    Logging.send($log_file, Logger::DEBUG, "data receive : #{data}")
    case data["cmd"]
      when "file"
        label = data["data"]
        date_scraping = data["date_scraping"]
        id_file = data["id_file"]
        user = data["user"]
        pwd = data["pwd"]
        p "download file #{id_file} from #{who}(#{ip}:#{port})"
        get_file(id_file, user, pwd)
        # load file id_file to DB with spawn
        # ==>>>
        close_connection
      when "exit"
        close_connection
        EventMachine.stop
      else
        Logging.send($log_file, Logger::ERROR, "unknown action : #{data["cmd"]}")
    end
  end

  def unbind
  end

  def get_file(id_file, user, pwd)
    begin
      ftp = Net::FTP.new(@host_ftp_server)
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
ftp_server_ip = scraper_server_ip = "localhost"
listening_port = 9002 # port d'ecoute du load_server
scraper_server_port = 9003




#--------------------------------------------------------------------------------------------------------------------
# INPUT
#--------------------------------------------------------------------------------------------------------------------
ARGV.each { |arg|
  listening_port = arg.split("=")[1] if arg.split("=")[0] == "--port"
  ftp_server_ip = scraper_server_ip = arg.split("=")[1] if arg.split("=")[0] == "--scraper_server_ip"
  scraper_server_port = arg.split("=")[1] if arg.split("=")[0] == "--scraper_server_port"
} if ARGV.size > 0

Logging.send($log_file, Logger::INFO, "parameters of load server : ")
Logging.send($log_file, Logger::INFO, "listening port : #{listening_port}")
Logging.send($log_file, Logger::INFO, "ftp and scraper server ip : #{ftp_server_ip}")
Logging.send($log_file, Logger::INFO, "scraper server port : #{scraper_server_port}")


#--------------------------------------------------------------------------------------------------------------------
# MAIN
#--------------------------------------------------------------------------------------------------------------------

# démarrage du server
EventMachine.run {
  Signal.trap("INT") { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }
  Logging.send($log_file, Logger::INFO, "load server is starting")
  EventMachine.start_server "0.0.0.0", listening_port, LoadServer, ftp_server_ip

  # recuperer les fichiers jamais chargés en base
  begin
    s = TCPSocket.new scraper_server_ip, scraper_server_port
    s.puts JSON.generate({"who" => "load server", "cmd" => "send_me_all_files"})
    s.close
    p "request to scraper server, send me all files !!"
    Logging.send($log_file, Logger::INFO, "request to scraper server, send me all files !!")
  rescue Exception => e
    Logging.send($log_file, Logger::FATAL, "request to scraper server, to retrieve all files, failed : #{e.message}")
  end
}
Logging.send($log_file, Logger::INFO, "load server stopped")

#--------------------------------------------------------------------------------------------------------------------
# END
#--------------------------------------------------------------------------------------------------------------------
