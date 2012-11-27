#!/usr/bin/env ruby -w
# encoding: UTF-8

require File.dirname(__FILE__) + '/../lib/logging'
#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------



module Common
  LOG_FILE = $log_file

  def information(msg)
    Logging.send(LOG_FILE, Logger::INFO, msg)
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
      Logging.send(LOG_FILE, Logger::WARN, "File <#{dir}#{type_file}-#{label}-#{date}#{volum}.txt> is not found")
    Dir.glob("#{dir}#{type_file}-#{label}-*#{volum}.txt").sort{|a, b| b<=>a}[0]
    end
  end



  def warning(msg)
    Logging.send(LOG_FILE, Logger::WARN, msg)
    p "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} => #{msg}"
  end

  def alert(msg)
    Logging.send(LOG_FILE, Logger::ERROR, msg)
    p "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} => #{msg}"
  end

  def error(msg)
    Logging.send(LOG_FILE, Logger::ERROR, msg)
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
end