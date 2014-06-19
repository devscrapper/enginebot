require 'rubygems' # if you use RubyGems
require 'socket'
require 'eventmachine'
require_relative 'flow_list'

module Flowing
  class FlowConnection < EventMachine::Connection
    attr :logger, :pages_in_mem


    def initialize(logger, pages_in_mem)
      @logger = logger
      @pages_in_mem = pages_in_mem
    end

    def receive_data param
      @logger.an_event.debug "data receive <#{param}>"
      begin
        Thread.new(Socket.unpack_sockaddr_in(get_peername)[1]) { |ip_ftp_server|

          begin
            data = YAML::load param
            data["data"].merge!({"ip_ftp_server" => ip_ftp_server})
            type_flow = data["type_flow"]
            data_type_flow = data["data"]
            @logger.an_event.debug data
            context = []
            context << type_flow
            @logger.ndc context
            @logger.an_event.debug "type_flow <#{type_flow}>"
            @logger.an_event.debug "data type_flow <#{data_type_flow}>"
            @logger.an_event.debug "context <#{context}>"
            Flowlist.new(data_type_flow, @pages_in_mem).method(type_flow.gsub("-", "_")).call()
          rescue Exception => e
            @logger.an_event.error "cannot manage flow <#{type_flow.gsub("-", "_")}>"
            @logger.an_event.debug e
          end
        }
      rescue Exception => e
        @logger.an_event.error "cannot thread input flow"
        @logger.an_event.debug e
      end
      close_connection
    end


  end
end