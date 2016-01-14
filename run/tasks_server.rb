#!/usr/bin/env ruby -w
# encoding: UTF-8
require 'yaml'
require_relative '../lib/logging'
require_relative '../lib/parameter'
require_relative '../model/tasking/connection'
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
  $calendar_server_port = parameters.calendar_server_port #TODO remplacer par une variable passée à la Connectiontask qui la passera à l'object Task dont héritera toutes les actions
  listening_port = parameters.listening_port
  $statupweb_server_ip = parameters.statupweb_server_ip
  $statupweb_server_port = parameters.statupweb_server_port

  if listening_port.nil? or
      $calendar_server_port.nil? or
      $statupweb_server_ip.nil? or
      $statupweb_server_port.nil? or
      $debugging.nil? or
      $staging.nil?
    $stderr << "some parameters not define" << "\n"
    exit(1)
  end
end

logger = Logging::Log.new(self, :staging => $staging, :id_file => File.basename(__FILE__, ".rb"), :debugging => $debugging)


logger.a_log.info "parameters of tasks server :"
logger.a_log.info "listening port : #{listening_port}"
logger.a_log.info "statupweb server ip : #{$statupweb_server_ip}"
logger.a_log.info "statupweb server port : #{$statupweb_server_port}"
logger.a_log.info "calendar server port : #{$calendar_server_port}"
logger.a_log.info "debugging : #{$debugging}"
logger.a_log.info "staging : #{$staging}"

include Tasking
#--------------------------------------------------------------------------------------------------------------------
# MAIN
#--------------------------------------------------------------------------------------------------------------------
EventMachine.run {
  Signal.trap("INT") { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }


  logger.a_log.info "tasks server is running"
  EventMachine.start_server "localhost", listening_port, TaskConnection, logger
}
logger.a_log.info "tasks server stopped"




