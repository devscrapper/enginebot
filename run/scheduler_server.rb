#!/usr/bin/env ruby -w
# encoding: UTF-8
require 'yaml'
require 'eventmachine'
require_relative '../lib/logging'
require_relative '../lib/parameter'
require_relative '../model/scheduler'

#--------------------------------------------------------------------------------------------------------------------
# LOAD PARAMETER
#--------------------------------------------------------------------------------------------------------------------
begin
  parameters = Parameter.new(__FILE__)
rescue Exception => e
  STDERR << e.message
else
  $staging = parameters.environment
  $debugging = parameters.debugging
  authentification_server_port = parameters.authentification_server_port
  ftp_server_port = parameters.ftp_server_port
  inputflow_factories = parameters.inputflow_factories
  delay_periodic_scan = parameters.delay_periodic_scan


  if authentification_server_port.nil? or
      ftp_server_port.nil? or
      inputflow_factories.nil? or
      $debugging.nil? or
      $staging.nil?
    STDERR << "some parameters not define"
    exit(1)
  end


  logger = Logging::Log.new(self, :staging => $staging, :id_file => File.basename(__FILE__, ".rb"), :debugging => $debugging)

  logger.a_log.info "parameters of scheduler server :"
  logger.a_log.info "authentification_server_port : #{authentification_server_port}"
  logger.a_log.info "ftp_server_port : #{ftp_server_port}"
  logger.a_log.info "inputflow factories : #{inputflow_factories}"
  logger.a_log.info "delay_periodic_scan : #{delay_periodic_scan}"
  logger.a_log.info "debugging : #{$debugging}"
  logger.a_log.info "staging : #{$staging}"


#--------------------------------------------------------------------------------------------------------------------
# MAIN
#--------------------------------------------------------------------------------------------------------------------
  logger.a_log.info "scheduler server is running"

  EM.run do
    Signal.trap("INT") { EventMachine.stop; }
    Signal.trap("TERM") { EventMachine.stop; }

    inputflow_factories.each { |os_label, version|
      version.each { |version_label, input_flow|
        s = Scheduler.new(os_label, version_label, input_flow, delay_periodic_scan, authentification_server_port, ftp_server_port, logger)
        s.scan_visit_file
      }
    }
  end
  logger.a_log.info "calendar server stopped"
end