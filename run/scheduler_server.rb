#!/usr/bin/env ruby -w
# encoding: UTF-8
require 'yaml'
require 'eventmachine'
require 'rufus-scheduler'
require_relative '../lib/logging'
require_relative '../lib/parameter'
require_relative '../model/scheduler'
require_relative '../model/geolocation'
require_relative '../lib/supervisor'


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
  inputflow_factories = parameters.inputflow_factories
  delay_periodic_scan = parameters.delay_periodic_scan
  delay_periodic_send_geolocation = parameters.delay_periodic_send_geolocation
  periodicity_supervision = parameters.periodicity_supervision


  if inputflow_factories.nil? or
      $debugging.nil? or
      $staging.nil? or
      periodicity_supervision.nil?
    $stderr << "some parameters not define" << "\n"
    exit(1)
  end


  logger = Logging::Log.new(self, :staging => $staging, :id_file => File.basename(__FILE__, ".rb"), :debugging => $debugging)

  logger.a_log.info "parameters of scheduler server :"
  logger.a_log.info "inputflow factories : #{inputflow_factories}"
  logger.a_log.info "delay_periodic_scan (second): #{delay_periodic_scan}"
  logger.a_log.info "delay_periodic_send_geolocation (minute): #{delay_periodic_send_geolocation}"
  logger.a_log.info "periodicity supervision : #{periodicity_supervision}"
  logger.a_log.info "debugging : #{$debugging}"
  logger.a_log.info "staging : #{$staging}"


#--------------------------------------------------------------------------------------------------------------------
# MAIN
#--------------------------------------------------------------------------------------------------------------------

  begin
    EM.run do
      logger.a_log.info "scheduler server is running"
      Signal.trap("INT") { EventMachine.stop; }
      Signal.trap("TERM") { EventMachine.stop; }
      # supervision
      Rufus::Scheduler.start_new.every periodicity_supervision do
        Supervisor.send_online(File.basename(__FILE__, '.rb'))
      end

      #TODO solution à revisiter de publication des geolocations qd la ou les solution finales de recuperation des geolocations
      #TODO seront terminées
      Geolocation.send(inputflow_factories, logger)
      EM.add_periodic_timer(delay_periodic_send_geolocation * 60) do
        Geolocation.send(inputflow_factories, logger)
      end

      inputflow_factories.each { |os_label, version|
        version.each { |version_label, input_flow_server|
          s = Scheduler.new(os_label, version_label, input_flow_server, delay_periodic_scan, logger)
          s.scan_visit_file
        }
      }
    end

  rescue Exception => e
    logger.a_log.fatal e
    Supervisor.send_failure(File.basename(__FILE__, '.rb'), e)
    logger.a_log.warn "scheduler server restart"
    retry
  end
  logger.a_log.info "scheduler server stopped"
end