#!/usr/bin/env ruby -w
# encoding: UTF-8

require File.dirname(__FILE__) + '/../lib/logging'
#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------



module Common

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
      p $log_file
      Logging.send($log_file, Logger::ERROR, "ask new authentification from  localhost':#{$authentification_server_port} failed")
    end
    get_response
  end

  def push_file(id_file, last_volume = false)

      begin
        response = get_authentification
        s = TCPSocket.new $statupbot_server_ip, $statupbot_server_port
        port, ip = Socket.unpack_sockaddr_in(s.getsockname)
        data = {"who" => self.class.name,
                "where" => ip,
                "cmd" => "file",
                "type_file" => "published-visits",
                "id_file" => id_file,
                "last_volume" => last_volume,
                "user" => response["user"],
                "pwd" => response["pwd"]}
        Logging.send($log_file, Logger::DEBUG, "push file #{data}")
        s.puts JSON.generate(data)

        Logging.send($log_file, Logger::INFO, "push file #{id_file} from #{ip}:#{port} to #{$statupbot_server_ip}:#{$statupbot_server_port}")

        s.close
      rescue Exception => e
        Logging.send($log_file, Logger::ERROR, "push file #{id_file} failed to #{$statupbot_server_ip}:#{$statupbot_server_port} : #{e.message}")
      end

    end

  def information(msg)
    Logging.send($log_file, Logger::INFO, msg)
    p "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} => #{msg}"
  end

  def execute_next_task(cmd, label, date)
    s = TCPSocket.new 'localhost', $listening_port
    s.puts JSON.generate({"cmd" => cmd, "label" => label, "date_building" => date})
    s.close
  end

  def select_file(dir, type_file, label, date, vol=nil)
    volum = "-#{vol}" unless vol.nil?
    volum  = "" if vol.nil?
    if File.exist?("#{dir}#{type_file}-#{label}-#{date}#{volum}.txt")
      "#{dir}#{type_file}-#{label}-#{date}#{volum}.txt"
    else
      Logging.send($log_file, Logger::WARN, "File <#{dir}#{type_file}-#{label}-#{date}#{volum}.txt> is not found")
    Dir.glob("#{dir}#{type_file}-#{label}-*#{volum}.txt").sort{|a, b| b<=>a}[0]
    end
  end



  def warning(msg)
    Logging.send($log_file, Logger::WARN, msg)
    p "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} => #{msg}"
  end

  def alert(msg)
    Logging.send($log_file, Logger::ERROR, msg)
    p "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} => #{msg}"
  end

  def error(msg)
    Logging.send($log_file, Logger::ERROR, msg)
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
  module_function :alert
  module_function :warning
  module_function :error
  module_function :push_file
  module_function :get_authentification
end