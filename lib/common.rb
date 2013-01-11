#!/usr/bin/env ruby -w
# encoding: UTF-8

require "fileutils"
require File.dirname(__FILE__) + '/../lib/logging'
#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------


module Common
  SEPARATOR6 = "_"
  ARCHIVE = File.dirname(__FILE__) + "/../archive/"

  def send_data_to(ip_server, port_server, data)
    begin
      data_to_json = JSON.generate(data).strip
      s = TCPSocket.new ip_server, port_server
      s.puts data_to_json
      s.close
      Logging.send($log_file, Logger::DEBUG, "send to #{ip_server}:#{port_server}, data :#{data_to_json}")
    rescue Exception => e
      Common.alert("send to #{ip_server}:#{port_server} failed : #{e.message}")
    end
  end



def get_authentification
  begin
    s = TCPSocket.new $authentification_server_ip, $authentification_server_port
    s.puts JSON.generate({"who" => self.class.name, "cmd" => "get"})
    get_response = JSON.parse(s.gets)
    port, ip = Socket.unpack_sockaddr_in(s.getsockname)

    Logging.send($log_file, Logger::INFO, "ask new authentification from  #{ip}:#{port} to 'localhost':#{$authentification_server_port}")
    Logging.send($log_file, Logger::DEBUG, "new authentification #{get_response} from  #{ip}:#{port} to 'localhost':#{$authentification_server_port}")
    s.close
  rescue Exception => e
    Logging.send($log_file, Logger::ERROR, "ask new authentification from  localhost':#{$authentification_server_port} failed")
  end
  get_response
end

def push_file(id_file, last_volume = false)

  begin
    response = get_authentification
    data = {"who" => self.class.name,
            "where" => ip,
            "cmd" => "file",
            "type_file" => "published-visits",
            "id_file" => id_file,
            "last_volume" => last_volume,
            "user" => response["user"],
            "pwd" => response["pwd"]}

    send_data_to($statupbot_server_ip, $statupbot_server_port, data)
  rescue Exception => e
    alert("push file #{id_file} to #{$statupbot_server_ip}:#{$statupbot_server_port} failed")
  end

end

def get_file(id_file, host_ftp_server, user, pwd)
  begin
    ftp = Net::FTP.new(host_ftp_server)
    ftp.login(user, pwd)
    ftp.gettextfile(id_file, INPUT + id_file)
    ftp.delete(id_file)
    #TODO archiver le vieux fichier => à valider
    /(?<type_file>(.+))_(?<label>(.+))_(?<date>(.+))_(?<vol>(.+))/ =~ id_file
    p "#{INPUT}#{Regexp.last_match(:type_file)}#{SEPARATOR6}#{Regexp.last_match(:label)}*.txt"
    Dir.glob("#{INPUT}#{Regexp.last_match(:type_file)}#{SEPARATOR6}#{Regexp.last_match(:label)}*.txt").each { |file|
      FileUtils.mv(file, ARCHIVE, :force => true) if File.ctime(file) < File.ctime(INPUT + id_file)
    }
    ftp.close

    Logging.send($log_file, Logger::INFO, "download file, #{id_file}to #{INPUT + id_file}")
  rescue Exception => e
    Logging.send($log_file, Logger::FATAL, "download file, #{id_file} failed #{e.message}")
  end
end

def information(msg)
  Logging.send($log_file, Logger::INFO, msg)
  p "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} => #{msg}"
end

def execute_next_task(cmd, label, date)
  begin
    data = {"cmd" => cmd, "label" => label, "date_building" => date}
    send_data_to("localhost", $listening_port, data)
  rescue Exception => e
    alert("execute next task #{cmd} for #{label} failed")
  end
end

def select_file(dir, type_file, label, date, vol=nil)
  file = id_file(dir, type_file, label, date, vol)
  if File.exist?(file)
    file
  else
    Logging.send($log_file, Logger::WARN, "File <#{file}> is not found")
    volum = "#{SEPARATOR6}#{vol}" unless vol.nil?
    volum = "" if vol.nil?
    #TODO corriger le moyen de selection : ne pas s'appuyer sur le nom du fichier mais plutot la date de creation
    Dir.glob("#{dir}#{type_file}#{SEPARATOR6}#{label}#{SEPARATOR6}*#{volum}.txt").sort { |a, b| b<=>a }[0]
  end
end

def archive_file(dir, type_file, label, vol=nil)
  volum = "#{SEPARATOR6}#{vol}" unless vol.nil?
  volum = "" if vol.nil?
  FileUtils.mv Dir.glob("#{dir}#{type_file}#{SEPARATOR6}#{label}#{SEPARATOR6}*#{volum}*"), ARCHIVE, :force => true
end

def id_file(dir, type_file, label, date, vol=nil, ext="txt")
  volum = "#{SEPARATOR6}#{vol}" unless vol.nil?
  volum = "" if vol.nil?
  "#{dir}#{type_file}#{SEPARATOR6}#{label}#{SEPARATOR6}#{date}#{volum}.#{ext}"
end

def open_file(dir, type_file, label, date, vol=nil, ext="txt")
  #volum = "#{SEPARATOR6}#{vol}" unless vol.nil?
  #volum = "" if vol.nil?
  #p Dir.glob("#{dir}#{type_file}#{SEPARATOR6}#{label}#{SEPARATOR6}*#{volum}")
  #FileUtils.mv Dir.glob("#{dir}#{type_file}#{SEPARATOR6}#{label}#{SEPARATOR6}*#{volum}"), ARCHIVE, :force => true
  archive_file(dir, type_file, label, vol)
  File.open(id_file(dir, type_file, label, date, vol, ext), "w:UTF-8")
end

def warning(msg, line=nil)
  Logging.send($log_file, Logger::WARN, msg, line)
  p "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} => #{msg}"
end

def alert(msg, line=nil)
  Logging.send($log_file, Logger::ERROR, msg, line)
  p "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} => #{msg}"
end

def error(msg, line=nil)
  Logging.send($log_file, Logger::ERROR, msg, line)
  p "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} ERROR => #{msg}"
end

def min(a, b)
  a < b ? a : b
end

def max(a, b)
  a > b ? a : b
end

module_function :min
module_function :max
module_function :information
module_function :execute_next_task
module_function :select_file
module_function :id_file
module_function :archive_file
module_function :open_file
module_function :alert
module_function :warning
module_function :error
module_function :push_file
module_function :get_authentification
module_function :send_data_to
module_function :get_file
end