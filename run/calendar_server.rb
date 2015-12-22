#!/usr/bin/env ruby -w
# encoding: UTF-8
require 'yaml'
require 'rufus-scheduler'
require_relative '../lib/logging'
require_relative '../model/planning/calendar'
require_relative '../model/planning/calendar_connection_http'


#--------------------------------------------------------------------------------------------------------------------
# INIT
#--------------------------------------------------------------------------------------------------------------------
PARAMETERS = File.dirname(__FILE__) + "/../parameter/" + File.basename(__FILE__, ".rb") + ".yml"
ENVIRONMENT= File.dirname(__FILE__) + "/../parameter/environment.yml"
listening_port = 9104
scrape_server_port = 9101
periodicity = "0 0 * * * 1-7 Europe/Paris"
$staging = "production"
$debugging = false
#--------------------------------------------------------------------------------------------------------------------
# INPUT
#--------------------------------------------------------------------------------------------------------------------
begin
  environment = YAML::load(File.open(ENVIRONMENT), "r:UTF-8")
  $staging = environment["staging"] unless environment["staging"].nil?
rescue Exception => e
  $stderr << "loading parameter file #{ENVIRONMENT} failed : #{e.message}"  << "\n"
end
  #TODO utiliser la librairie parameter
begin
  params = YAML::load(File.open(PARAMETERS), "r:UTF-8")
  listening_port = params[$staging]["listening_port"] unless params[$staging]["listening_port"].nil?
  scrape_server_port = params[$staging]["scrape_server_port"] unless params[$staging]["scrape_server_port"].nil?
  periodicity = params[$staging]["periodicity"] unless params[$staging]["periodicity"].nil?
  $debugging = params[$staging]["debugging"] unless params[$staging]["debugging"].nil?
rescue Exception => e
  $stderr << "loading parameters file #{PARAMETERS} failed : #{e.message}" << "\n"
end

logger = Logging::Log.new(self, :staging => $staging, :id_file => File.basename(__FILE__, ".rb"), :debugging => $debugging)


logger.a_log.info "parameters of calendar server :"
logger.a_log.info "listening port : #{listening_port}"
logger.a_log.info "scraper server port : #{scrape_server_port}"
logger.a_log.info "periodicity : #{periodicity}"
logger.a_log.info "debugging : #{$debugging}"
logger.a_log.info "staging : #{$staging}"

include Planning
#--------------------------------------------------------------------------------------------------------------------
# MAIN
#--------------------------------------------------------------------------------------------------------------------
EventMachine.run {
  Signal.trap("INT") { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  calendar = Calendar.new(scrape_server_port)
  scheduler = Rufus::Scheduler.start_new
  scheduler.cron periodicity do
    begin
      now = Time.now #
      start_date = Date.new(now.year, now.month, now.day)
      hour = now.hour
      min = now.min
      calendar.execute_all_at(start_date, hour, min)
      calendar.execute_all_which_pre_tasks_over_is_complet
    rescue Exception => e
      logger.a_log.fatal "cannot execute events at date : #{start_date}, and hour #{hour} : #{e.message}"

    end
  end
  logger.a_log.info "planning is running"

  logger.a_log.info "calendar server is running"
  EventMachine.start_server "0.0.0.0", listening_port, CalendarConnection, logger, calendar
}
logger.a_log.info "calendar server stopped"


