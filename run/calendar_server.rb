# encoding: UTF-8
require 'yaml'
require 'rufus-scheduler'
require_relative '../lib/logging'
require_relative '../lib/parameter'
require_relative '../model/planning/calendar'
require_relative '../model/planning/connection'


#--------------------------------------------------------------------------------------------------------------------
# LOAD PARAMETER
#--------------------------------------------------------------------------------------------------------------------
begin
  parameters = Parameter.new(__FILE__)

rescue Exception => e
  $stderr << e.message << "\n"

else
  $staging = parameters.environment
  $debugging = parameters.debugging
  listening_port = parameters.listening_port
  periodicity = parameters.periodicity

  if listening_port.nil? or
      periodicity.nil? or
      $debugging.nil? or
      $staging.nil?
    $stderr << "some parameters not define" << "\n"
    exit(1)
  end
end
logger = Logging::Log.new(self, :staging => $staging, :id_file => File.basename(__FILE__, ".rb"), :debugging => $debugging)

logger.a_log.info "parameters of calendar server :"
logger.a_log.info "listening port : #{listening_port}"
logger.a_log.info "periodicity : #{periodicity}"
logger.a_log.info "debugging : #{$debugging}"
logger.a_log.info "staging : #{$staging}"

include Planning
#--------------------------------------------------------------------------------------------------------------------
# MAIN
#--------------------------------------------------------------------------------------------------------------------
begin
  EventMachine.run {
    Signal.trap("INT") { EventMachine.stop }
    Signal.trap("TERM") { EventMachine.stop }

    calendar = Calendar.new
    scheduler = Rufus::Scheduler.start_new
    scheduler.cron periodicity do
      now = Time.now #
      start_date = Date.new(now.year, now.month, now.day)
      hour = now.hour
      min = now.min
      begin
        calendar.execute_all_events_at(start_date, hour, min)

      rescue Exception => e
        logger.a_log.fatal "cannot execute events at date : #{start_date}, and hour #{hour} : #{e.message}"

      end
      begin
        # en developpement, afin de tester plus facilement, on n'attend pas le jour de décenchement des events
        calendar.execute_all_events_which_all_pre_tasks_are_over($staging == 'development' ? nil : start_date)

      rescue Exception => e
        logger.a_log.fatal "cannot execute events at date : #{start_date}, and hour #{hour} : #{e.message}"

      end
    end

    logger.a_log.info "calendar server is running"
    EventMachine.start_server "0.0.0.0", listening_port, Connection, logger, calendar
  }
rescue Exception => e
  logger.a_log.fatal e
  logger.a_log.warn "calendar server restart"
  retry
else
end
logger.a_log.info "calendar server stopped"


