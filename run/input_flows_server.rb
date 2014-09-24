#!/usr/bin/env ruby -w
# encoding: UTF-8
require 'yaml'
require_relative '../lib/logging'
require_relative '../model/flowing/flow_connection'


#--------------------------------------------------------------------------------------------------------------------
# INIT
#--------------------------------------------------------------------------------------------------------------------
PARAMETERS = File.dirname(__FILE__) + "/../parameter/" + File.basename(__FILE__, ".rb") + ".yml"
ENVIRONMENT= File.dirname(__FILE__) + "/../parameter/environment.yml"
listening_port = 9105 # port d'ecoute
task_server_port = 9101
pages_in_mem = true
$staging = "production"
$debugging = false
#--------------------------------------------------------------------------------------------------------------------
# INPUT
#--------------------------------------------------------------------------------------------------------------------
begin
  environment = YAML::load(File.open(ENVIRONMENT), "r:UTF-8")
  $staging = environment["staging"] unless environment["staging"].nil?
rescue Exception => e
  $stderr << "loading parameter file #{ENVIRONMENT} failed : #{e.message}"    << "\n"
end

begin
  params = YAML::load(File.open(PARAMETERS), "r:UTF-8")
  listening_port = params[$staging]["listening_port"] unless params[$staging]["listening_port"].nil?
  task_server_port = params[$staging]["task_server_port"] unless params[$staging]["task_server_port"].nil?
  pages_in_mem = params[$staging]["pages_in_mem"] unless params[$staging]["pages_in_mem"].nil?

  $debugging = params[$staging]["debugging"] unless params[$staging]["debugging"].nil?
rescue Exception => e
  $stderr << "loading parameters file #{PARAMETERS} failed : #{e.message}"  << "\n"
end

logger = Logging::Log.new(self, :staging => $staging, :id_file => File.basename(__FILE__, ".rb"), :debugging => $debugging)


logger.a_log.info "parameters of input flows server :"
logger.a_log.info "listening port : #{listening_port}"
logger.a_log.info "task server port : #{task_server_port}"
logger.a_log.info "pages in memory : #{pages_in_mem}"
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
  EventMachine.start_server "0.0.0.0", listening_port, FlowConnection, logger, pages_in_mem
}
logger.a_log.info "input flows server stopped"

