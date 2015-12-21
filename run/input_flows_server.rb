#!/usr/bin/env ruby -w
# encoding: UTF-8
require 'yaml'
require_relative '../lib/logging'
require_relative '../lib/parameter'
require_relative '../model/flowing/flow_connection'


#--------------------------------------------------------------------------------------------------------------------
# INIT
#--------------------------------------------------------------------------------------------------------------------

begin
  parameters = Parameter.new(__FILE__)
rescue Exception => e
  $stderr << e.message  << "\n"
else
  $staging = parameters.environment
  $debugging = parameters.debugging
  listening_port = parameters.listening_port
  calendar_server_port = parameters.calendar_server_port

  if listening_port.nil? or
      calendar_server_port.nil?  or
      $debugging.nil? or
      $staging.nil?
    $stderr << "some parameters not define"  << "\n"
    exit(1)
  end
end
  logger = Logging::Log.new(self, :staging => $staging, :id_file => File.basename(__FILE__, ".rb"), :debugging => $debugging)

logger.a_log.info "parameters of input flows server :"
logger.a_log.info "listening port : #{listening_port}"
logger.a_log.info "calendar server port : #{calendar_server_port}"
logger.a_log.info "debugging : #{$debugging}"
logger.a_log.info "staging : #{$staging}"

include Flowing
#--------------------------------------------------------------------------------------------------------------------
# MAIN
#--------------------------------------------------------------------------------------------------------------------
EventMachine.run {
  Signal.trap("INT") { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  logger.a_log.info "input flows server is starting"
  EventMachine.start_server "0.0.0.0", listening_port, FlowConnection, logger, calendar_server_port
}
logger.a_log.info "input flows server stopped"

