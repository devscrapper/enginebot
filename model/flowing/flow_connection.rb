require 'rubygems' # if you use RubyGems
require 'socket'
require 'eventmachine'
require_relative "../../model/communication"
require_relative '../flow'


module Flowing
  class FlowConnection < EventMachine::Connection
    INPUT = File.dirname(__FILE__) + "/../../input"
    attr :logger  ,
         :calendar_server_port


    def initialize(logger, calendar_server_port)
      @logger = logger
      @calendar_server_port= calendar_server_port
    end

    def receive_data param
      @logger.an_event.debug "data receive <#{param}>"
      close_connection


      begin
        ip_ftp_server = Socket.unpack_sockaddr_in(get_peername)[1]
        data = YAML::load param

        type_flow = data["type_flow"]
        basename = data["data"]["basename"]
        port_ftp_server = data["data"]["port_ftp_server"]
        user = data["data"]["user"]
        pwd = data["data"]["pwd"]
        last_volume = data["data"]["last_volume"]

        context = []
        context << type_flow
        @logger.ndc context
        @logger.an_event.debug "type_flow <#{type_flow}>"
        @logger.an_event.debug "context <#{context}>"

        input_flow = Flow.from_basename(INPUT, basename)
        input_flow.get(ip_ftp_server,
                       port_ftp_server,
                       user,
                       pwd)


      rescue Exception => e
        @logger.an_event.error "Flow #{basename} not downloaded #{e.message}"

      else
        @logger.an_event.info "Flow #{basename} downloaded"

        if last_volume
          task_name = type_flow.gsub("-", "_")

          # informe le calendar que la tache est terminée. En fonction Calendar pourra declencher d'autres taches
          @query = {"cmd" => "over"}
          @query.merge!({"object" => task_name})
          @query.merge!({"data" => {"policy_type" => input_flow.policy,
                                    "website_label" => input_flow.label,
                                    "date_building" => input_flow.date}
                        })

          begin
            response = Question.new(@query).ask_to("localhost", @calendar_server_port)

          rescue Exception => e
            @logger.an_event.error "calendar not informed : #{e.message}"

          else
            @logger.an_event.error "calendar not informed : #{response[:error]}"  if response[:state] == :ko
            response[:data] if response[:state] == :ok and !response[:data].nil?

          end
        end
      end


    end


  end
end