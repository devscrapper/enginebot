#encoding:UTF-8
require_relative '../flow'
require_relative '../../lib/error'
require_relative 'scheduler'
require 'em-http-server'
require 'em/deferrable'
require 'addressable/uri'

module Scheduling
  class Connection < EM::HttpServer::Server
    include Errors

    ARGUMENT_NOT_DEFINE = 1800
    ACTION_UNKNOWN = 1801
    ACTION_NOT_EXECUTE = 1802
    RESSOURCE_NOT_MANAGE = 1803
    VERBE_HTTP_NOT_MANAGE = 1804
    RESSOURCE_UNKNOWN = 1805
    DURATION_TOO_SHORT = 2100


    OUTPUT = File.expand_path(File.join("..", "..", "..", "output"), __FILE__)
    ARCHIVE = File.expand_path(File.join("..", "..", "..", "archive"), __FILE__)

    attr :inputflow_factories,
         :logger


    def initialize(logger, inputflow_factories)
      super
      @inputflow_factories = inputflow_factories
      @logger = logger
    end

    def process_http_request
      #------------------------------------------------------------------------------------------------------------------
      # REST : uri disponibles
      # GET
      # POST

      # PUT
      # http://localhost:9105/visits/published/?visit_id=#{visit_id}
      # "http://#{enginebot_host}:#{enginebot_port}/visits/restarted/?visit_id=#{visit_id}",
      # DELETE

      #------------------------------------------------------------------------------------------------------------------


      #------------------------------------------------------------------------------------------------------------------
      # Check input data
      #------------------------------------------------------------------------------------------------------------------
      action = proc {
        begin
          @logger.an_event.debug "@http_request_method : #{@http_request_method}"
          @logger.an_event.debug "@http_request_uri : #{@http_request_uri}"

          visit_flow = nil
          nul, ress_type, ress_id = @http_request_uri.split("/")

          @logger.an_event.debug "ress_type : #{ress_type}"
          @logger.an_event.debug "ress_id : #{ress_id}"

          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "ress_type"}) if ress_type.nil? or ress_type.empty?


          case @http_request_method
            #--------------------------------------------------------------------------------------------------------------
            # GET
            #--------------------------------------------------------------------------------------------------------------
            when "GET"


              #--------------------------------------------------------------------------------------------------------------
              # POST
              #--------------------------------------------------------------------------------------------------------------
            when "POST"


              #--------------------------------------------------------------------------------------------------------------
              # PUT
              #--------------------------------------------------------------------------------------------------------------

            when "PUT"
              #Flow : Windows-7_traffic_meshumeursinformatique_2016-03-07-13-17-00_537327c0-c1bb-0133-5867-00ffe049370b.yml
              # pas de respect de http, car maj ne renvoient pas la ressource maj
              # http://localhost:9105/visits/published/?visit_id=#{visit_id}
              #"http://#{enginebot_host}:#{enginebot_port}/visits/restarted/?visit_id=#{visit_id}",
              raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "ress_id"}) if ress_id.nil? or ress_id.empty?
              raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "query string"}) if @http_query_string.nil?
              query_values = Addressable::URI.parse("?#{@http_query_string}").query_values
              raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "visit_id"}) if query_values["visit_id"].nil? or query_values["visit_id"].empty?


              case ress_id
                when "published"
                  @logger.an_event.debug  File.join(OUTPUT, "*#{Flow::SEPARATOR}#{query_values["visit_id"]}.man")
                  visit_flow = Dir.glob(File.join(OUTPUT, "*#{Flow::SEPARATOR}#{query_values["visit_id"]}.man")).map { |file| Flow.from_absolute_path(file) }[0]

                when "restarted"
                  @logger.an_event.debug  File.join(ARCHIVE, "*#{Flow::SEPARATOR}#{query_values["visit_id"]}.yml")
                  visit_flow = Dir.glob(File.join(ARCHIVE, "*#{Flow::SEPARATOR}#{query_values["visit_id"]}.yml")).map { |file| Flow.from_absolute_path(file) }[0]

                else
                  raise "ress_id #{ress_id} not manage"
              end

              @logger.an_event.debug visit_flow
              unless visit_flow.nil?
                @logger.an_event.info "visit #{query_values["visit_id"]} file name found : #{visit_flow.absolute_path}"
                server = nil
                pattern = visit_flow.type_flow
                @inputflow_factories.each { |os_label, version|
                  version.each { |version_label, input_flow_server|
                    if input_flow_server[:pattern] == pattern
                      server = input_flow_server[:servers][:server1]
                      @logger.an_event.debug "server inputflow target #{server}"

                      begin
                        ip = server[:ip]
                        port = server[:port]
                        visit_details = visit_flow.read
                        wait(60, true, 1.2) {
                          response = RestClient.post "http://#{ip}:#{port}/visits/new",
                                                     visit_details,
                                                     :content_type => :json,
                                                     :accept => :json

                        }

                      rescue Exception => e
                        @logger.an_event.error "push visit flow #{visit_flow.basename} to input flow server #{ip}:#{port}"
                        raise "visit not published to statupbot #{ip} : #{e.message}"

                      else
                        @logger.an_event.info "push visit flow #{visit_flow.basename} to input flow server #{ip}:#{port}"

                        case ress_id
                          when "published"
                            visit_flow.archive

                          when "restarted"

                        end

                        #informe statupweb de la creation d'une nouvelle visite
                        # en cas d'erreur on ne leve as de'exception car c'est de la communication
                        begin
                          wait(60, true, 1.2) {
                            response = RestClient.patch "http://#{$statupweb_server_ip}:#{$statupweb_server_port}/visits/#{query_values["visit_id"]}",
                                                        JSON.generate({:state => :published}),
                                                        :content_type => :json,
                                                        :accept => :json
                          }

                        rescue Exception => e
                          @logger.an_event.error "update scheduled state of visit #{query_values["visit_id"]} to statupweb (#{$statupweb_server_ip}:#{$statupweb_server_port}) => #{e.message}"
                          raise "visit #{query_values["visit_id"]} state not scheduled : #{e.message}"

                        else
                        ensure
                        end
                      end
                      break # on sort de la boucle des input_flow_server
                    end
                  }
                }

              else
                case ress_id
                  when "published"
                    @logger.an_event.error "visit #{query_values["visit_id"]} file name not found in #{OUTPUT}"

                  when "restarted"
                    @logger.an_event.error "visit #{query_values["visit_id"]} file name not found in #{ARCHIVE}"
                end

                raise "visit #{query_values["visit_id"]} file not found"

              end
            #--------------------------------------------------------------------------------------------------------------
            # PATCH
            #--------------------------------------------------------------------------------------------------------------
            when "PATCH"


              #--------------------------------------------------------------------------------------------------------------
              # DELETE
              #--------------------------------------------------------------------------------------------------------------
            when "DELETE"

            else
              raise Error.new(VERBE_HTTP_NOT_MANAGE, :values => {:verb => @http_request_method})
          end

        rescue Error => e
          @logger.an_event.error e.message
          results = e

        rescue Exception => e
          @logger.an_event.fatal e
          results = e

        else
          results = visit_flow # as usual, the last expression evaluated in the block will be the return value.

        ensure

        end
      }

      callback = proc { |results|
        # do something with result here, such as send it back to a network client.

        response = EM::DelegatedHttpResponse.new(self)

        if results.is_a?(Error)
          case results.code

            when ARGUMENT_NOT_DEFINE, DURATION_TOO_SHORT
              response.status = 400

            when RESSOURCE_NOT_MANAGE, RESSOURCE_UNKNOWN
              response.status = 404

            when VERBE_HTTP_NOT_MANAGE
              response.status = 405

            else
              response.status = 501

          end

        elsif results.is_a?(Exception)
          response.status = 500

        else
          response.status = 200
        end

        response.content_type 'application/json'
        response.content = results.to_json
        response.send_response
        close_connection_after_writing
      }

      if $staging == "development" #en dev tout ext exécuté hors thread pour pouvoir debugger
        begin
          results = action.call

        rescue Exception => e
          @logger.an_event.error e.message
          callback.call(e)
        else
          callback.call(results)

        end
      else # en test & production tout est executé dans un thread
        EM.defer(action, callback)

      end
    end

    def http_request_errback e
      # printing the whole exception
      puts e.inspect
    end


    private

    # si pas de bloc passé => wait pour une duree passé en paramètre
    # si un bloc est passé => evalue le bloc tant que le bloc return false, leve une exception, ou que le timeout n'est pas atteind
    # qd le timeout est atteint, si exception == true alors propage l'exception hors du wait

    def wait(timeout, exception = false, interval=0.2)

      if !block_given?
        sleep(timeout)
        return
      end

      timeout = interval if $staging == "development" # on execute une fois

      while (timeout > 0)
        sleep(interval)
        timeout -= interval
        begin
          return if yield
        rescue Exception => e
          p "try again : #{e.message}"
        else
          p "try again."
        end
      end

      raise e if !e.nil? and exception == true

    end
  end


end