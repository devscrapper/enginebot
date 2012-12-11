#!/usr/bin/env ruby -w
# encoding: UTF-8

require 'eventmachine'
require File.dirname(__FILE__) + '/../lib/common'
require File.dirname(__FILE__) + '/../lib/logging'
require File.dirname(__FILE__) + '/../model/objective'
require 'socket'
#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------


module Building_objectives
#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------
  INPUT = File.dirname(__FILE__) + "/../input/"
  TMP = File.dirname(__FILE__) + "/../tmp/"
  SEPARATOR="%SEP%"
  EOFLINE="%EOFL%"
  SEPARATOR2=";"
  SEPARATOR3="!"
  SEPARATOR4="|"
  SEPARATOR5=","
  EOFLINE2 ="\n"
  LOG_FILE = File.dirname(__FILE__) + "/../log/" + File.basename(__FILE__, ".rb") + ".log"

#inputs

# local
  attr


#--------------------------------------------------------------------------------------------------------------
# Publishing
#--------------------------------------------------------------------------------------------------------------
#
# --------------------------------------------------------------------------------------------------------------

  def Publishing(label, date,
      change_count_visits_percent,
      change_bounce_visits_percent,
      direct_medium_percent,
      organic_medium_percent,
      referral_medium_percent)

    begin
      information("Building objectives for #{label} is starting")
      Logging.send(LOG_FILE, Logger::DEBUG, "change_count_visits_percent #{change_count_visits_percent}")
      Logging.send(LOG_FILE, Logger::DEBUG, "change_bounce_visits_percent #{change_bounce_visits_percent}")
      Logging.send(LOG_FILE, Logger::DEBUG, "direct_medium_percent #{direct_medium_percent}")
      Logging.send(LOG_FILE, Logger::DEBUG, "organic_medium_percent #{organic_medium_percent}")
      Logging.send(LOG_FILE, Logger::DEBUG, "referral_medium_percent #{referral_medium_percent}")

      hourly_daily_distribution = []


      hourly_daily_distribution_file = id_file(TMP, "hourly-daily-distribution",label,date)
      behaviour_file = id_file(TMP,"behaviour",label,date)
      if !File.exist?(hourly_daily_distribution_file)
        alert("Publishing objectives for #{label} fails because #{hourly_daily_distribution_file} file is missing")
        return false
      end
      if !File.exist?(behaviour_file)
        alert("Publishing objectives for #{label} fails because #{behaviour_file} file is missing")
        return false
      end

      behaviour = File.open(behaviour_file, "r:BOM|UTF-8:-").readlines(EOFLINE2)

      hourly_daily_distribution = File.open(hourly_daily_distribution_file, "r:BOM|UTF-8:-").readlines(EOFLINE2)
      if behaviour.size != hourly_daily_distribution.size

        alert("Publishing objectives for #{label} fails because behaviour and hourly_daily_distribution have not the same number of days #{behaviour.size} and #{hourly_daily_distribution.size}")
        return false
      end
      p = ProgressBar.create(:title => "Building objectives", :length => 180, :starting_at => 0, :total => behaviour.size, :format => '%t, %c/%C, %a|%w|')
      day = next_monday(date)
      behaviour.size.times { |line|
        splitted_behaviour = behaviour[line].strip.split(SEPARATOR2)
        splitted_hourly_daily_distribution = hourly_daily_distribution[line].strip.split(SEPARATOR2)
        obj = Objective.new(label, day ,
                            (splitted_behaviour[5].to_i * (1 + (change_count_visits_percent.to_f / 100))).to_i,
                            (splitted_behaviour[2].to_f * (1 + (change_bounce_visits_percent.to_f / 100))).round(2),
                            splitted_behaviour[1].to_f.round(2),
                            splitted_behaviour[3].to_f.round(2),
                            splitted_behaviour[4].to_f.round(2),
                            10, #min_durations
                            2, #min_pages
                            direct_medium_percent,
                            referral_medium_percent,
                            organic_medium_percent,
                            splitted_hourly_daily_distribution[1])
        obj.save
        p.increment
        day = day.next_day(1)
      }
      information("Building objectives for #{label} is over")
    rescue Exception => e
      error(e.message)
    end
  end

  #private
  def next_monday(date)
    today = Date.parse(date)
    return today.next_day(1) if today.sunday?
    return today if today.monday?
    return today.next_day(6) if today.tuesday?
    return today.next_day(5) if today.wednesday?
    return today.next_day(4) if today.thursday?
    return today.next_day(3) if today.friday?
    return today.next_day(2) if today.saturday?
end

def alert(msg)
  Common.alert(msg)
end

def information(msg)
  Common.information(msg)
end

def error(msg)
  Common.error(msg)
end

def execute_next_task(task, label, date)
  Common.execute_next_task(task, label, date)
end

def select_file(dir, type_file, label, date)
  Common.select_file(dir, type_file, label, date)
end

  def id_file(dir, type_file, label, date, vol=nil, ext="txt")
    Common.id_file(dir, type_file, label, date, vol, ext)
  end
# public
module_function :Publishing
# private
module_function :next_monday
module_function :error
module_function :alert
module_function :information
module_function :execute_next_task
module_function :select_file
  module_function :id_file
end