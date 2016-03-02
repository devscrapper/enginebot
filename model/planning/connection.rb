#encoding:UTF-8
require_relative "event"
require_relative '../../lib/error'
require 'em-http-server'
require 'em/deferrable'
require 'addressable/uri'

module Planning
  class Connection < EM::HttpServer::Server
    include Errors
    ARGUMENT_NOT_DEFINE = 1800
    ACTION_UNKNOWN = 1801
    ACTION_NOT_EXECUTE = 1802
    RESSOURCE_NOT_MANAGE = 1803
    VERBE_HTTP_NOT_MANAGE = 1804
    DURATION_TOO_SHORT = 2100

    @@title_html = ""

    attr :calendar, # repository events
         :logger


    def initialize(logger, calendar)
      super
      @calendar = calendar
      @logger = logger
    end

    def process_http_request
      #------------------------------------------------------------------------------------------------------------------
      # REST : uri disponibles
      # GET
      # http://localhost:9104/calendar/online
      # http://localhost:9104/tasks/all
      # http://localhost:9104/tasks/today
      # http://localhost:9104/tasks/now
      # http://localhost:9104/tasks/monday ... sunday
      # http://localhost:9104/pre_task_over/all
      # http://localhost:9104/pre_task_over/today
      # POST
      # http://localhost:9104/policies/traffic  payload = { ... }
      # http://localhost:9104/policies/rank     payload = { ... }
      # http://localhost:9104/objectives/traffic  payload = { ... }
      # http://localhost:9104/objectives/rank      payload = { ... }
      # PATCH
      # http://localhost:9104/tasks/<taskname>/?state=start ou over ou fail  payload = {"policy_id" => @data["policy_id"], "task" => task}
      # DELETE
      # http://localhost:9104/policies/<policy_id>
      #------------------------------------------------------------------------------------------------------------------


      #------------------------------------------------------------------------------------------------------------------
      # Check input data
      #------------------------------------------------------------------------------------------------------------------
      action = proc {
        begin
          @logger.an_event.debug "@http_request_method : #{@http_request_method}"
          @logger.an_event.debug "@http_request_uri : #{@http_request_uri}"

          nul, ress_type, ress_id = @http_request_uri.split("/")

          @logger.an_event.debug "ress_type : #{ress_type}"
          @logger.an_event.debug "ress_id : #{ress_id}"

          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "ress_type"}) if ress_type.nil? or ress_type.empty?



          case @http_request_method
            #--------------------------------------------------------------------------------------------------------------
            # GET
            #--------------------------------------------------------------------------------------------------------------
            when "GET"

              @logger.an_event.info "list #{ress_id} events from repository"
              case ress_type
                when "calendar"
                  tasks = "OK"
                  @@title_html = "calendar online"

                when "tasks"
                  raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "ress_id"}) if ress_id.nil? or ress_id.empty?

                  if ["monday", "tuesday", "wednesday", "friday", "thursday", "saturday", "sunday"].include?(ress_id)
                    tasks = @calendar.all_events_on_date(Calendar.next_day(ress_id))
                    @@title_html = "On #{ress_id} tasks"

                  elsif ress_id == "all"
                    tasks = @calendar.all_events
                    @@title_html = "All tasks(#{tasks.size})"

                  elsif ress_id == "today"
                    tasks = @calendar.all_events_on_date(Date.today)
                    @@title_html = "Today #{Date.today} tasks(#{tasks.size})"

                  elsif ress_id == "running"
                    tasks = @calendar.all_events_running
                    @@title_html = "Running tasks(#{tasks.size})"

                  else
                    raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "query string"}) if @http_query_string.nil?
                    query_values = Addressable::URI.parse("?#{@http_query_string}").query_values

                    case ress_id
                      when "date"
                        raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "date"}) if query_values["date"].nil? or query_values["date"].empty?
                        tasks = @calendar.all_events_on_date(Date.parse(query_values["date"]))
                        @@title_html = "All tasks(#{tasks.size}) of date #{query_values["date"]}"

                      when "hour"
                        raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "date"}) if query_values["date"].nil? or query_values["date"].empty?
                        raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "hour"}) if query_values["hour"].nil? or query_values["hour"].empty?
                        tasks = @calendar.all_events_on_hour(Date.parse(query_values["date"]),
                                                             query_values["hour"].to_i)
                        @@title_html = "All tasks(#{tasks.size}) of date #{query_values["date"]} and hour #{query_values["hour"]}"

                      when "time"
                        raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "min"}) if query_values["min"].nil? or query_values["min"].empty?
                        raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "date"}) if query_values["date"].nil? or query_values["date"].empty?
                        raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "hour"}) if query_values["hour"].nil? or query_values["hour"].empty?
                        tasks = @calendar.all_events_on_time(Date.parse(query_values["date"]),
                                                             query_values["hour"].to_i,
                                                             query_values["min"].to_i)

                        @@title_html = "All tasks(#{tasks.size}) of date #{query_values["date"]} and hour #{query_values["hour"]} and min #{query_values["min"]}"
                      when "search"
                        raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "key"}) if query_values["key"].nil? or query_values["key"].empty?
                        tasks = @calendar.one(JSON.parse(query_values["key"]))
                        @@title_html = "Search task(#{tasks.size}) (key : #{JSON.parse(query_values["key"])}"

                      when "execute"
                        raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "id"}) if query_values["id"].nil? or query_values["id"].empty?
                        @calendar.execute_one(query_values["id"])
                        tasks = @calendar.all_events_running
                        @@title_html = "Running tasks(#{tasks.size})"

                      else
                        raise Error.new(RESSOURCE_NOT_MANAGE, :values => {:ressource => ress_id})

                    end
                  end
                else
                  raise Error.new(RESSOURCE_NOT_MANAGE, :values => {:ressource => ress_type})
                  @logger.an_event.warn "ressource #{ress_type} unmanage"
              end
              @logger.an_event.info "#{tasks.size} events for #{ress_id} from repository"
            #--------------------------------------------------------------------------------------------------------------
            # POST
            #--------------------------------------------------------------------------------------------------------------
            when "POST"
              @http_content = JSON.parse(@http_content, {:symbolize_names => true})
              @logger.an_event.debug "@http_content : #{@http_content}"
              raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "ress_id"}) if ress_id.nil? or ress_id.empty?
              case ress_type
                when "policies"
                  tasks = @calendar.register_policy(ress_id, @http_content)

                when "objectives"
                  tasks = @calendar.register_objective(ress_id, @http_content)

                else
                  raise Error.new(RESSOURCE_NOT_MANAGE, :values => {:ressource => ress_type})

              end
              @logger.an_event.info "save #{tasks.size} events of object #{ress_id} to calendar"
            #--------------------------------------------------------------------------------------------------------------
            # PUT
            #--------------------------------------------------------------------------------------------------------------

            when "PUT"
              # pas de respect de http, car maj ne renvoient pas la ressource maj

              #--------------------------------------------------------------------------------------------------------------
              # PATCH
              #--------------------------------------------------------------------------------------------------------------

            when "PATCH"
              # pas de respect de http, car maj ne renvoient pas la ressource maj
              raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "ress_id"}) if ress_id.nil? or ress_id.empty?
              raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "query string"}) if @http_query_string.nil?

              query_values = Addressable::URI.parse("?#{@http_query_string}").query_values
              raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "state"}) if query_values["state"].nil? or query_values["state"].empty?

              case ress_type
                when "tasks"
                  event_id = ress_id

                  case query_values["state"]
                    when "start"
                      @logger.an_event.info "update event_id #{event_id} with START to repository"
                      @calendar.event_is_start(event_id)

                    when "over"
                      @logger.an_event.info "update event_id #{event_id} with OVER to repository"
                      @calendar.event_is_over(event_id)

                    when "fail"
                      @logger.an_event.info "update event_id #{event_id} with FAIL to repository"
                      @calendar.event_is_fail(event_id)

                    else
                      raise Error.new(RESSOURCE_NOT_MANAGE, :values => {:ressource => query_values["state"]})
                  end

                else
                  raise Error.new(RESSOURCE_NOT_MANAGE, :values => {:ressource => ress_type})

              end

            #--------------------------------------------------------------------------------------------------------------
            # DELETE
            #--------------------------------------------------------------------------------------------------------------
            when "DELETE"
              # pas de respect de http, car maj ne renvoient pas la ressource maj
              raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "ress_id"}) if ress_id.nil? or ress_id.empty?
              @logger.an_event.info "delete events of the #{ress_type} policy id=#{ress_id} to repository"
              case ress_type
                when "traffics"
                  @calendar.delete_policy(ress_id.to_i, "traffic")
                when "ranks"
                  @calendar.delete_policy(ress_id.to_i, "rank")
                else
                  raise Error.new(RESSOURCE_NOT_MANAGE, :values => {:ressource => ress_type})
              end

            else
              raise Error.new(VERBE_HTTP_NOT_MANAGE, :values => {:verb => @http_request_method})
          end

        rescue Error, Exception => e
          @logger.an_event.fatal e.message
          results = e

        else
          results = tasks # as usual, the last expression evaluated in the block will be the return value.

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

            when RESSOURCE_NOT_MANAGE
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

        if @http[:accept].include?("text/html") and response.status == 200
          # formatage des données en html si aucune erreur et si accès avec un navigateur
          response.content_type 'text/html'
          response.content = @calendar.to_html(results, @@title_html) if results.is_a?(Array)
          response.content = results unless results.is_a?(Array)
        else
          response.content_type 'application/json'
          response.content = results.to_json

        end

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

  end


end