#encoding:UTF-8
require_relative "event"
require_relative "events"
require_relative '../../lib/error'
require 'em-http-server'
require 'em/deferrable'
require 'addressable/uri'

class CalendarConnection < EM::HttpServer::Server
  include Errors
  ARGUMENT_NOT_DEFINE = 1800
  ACTION_UNKNOWN = 1801
  ACTION_NOT_EXECUTE = 1802
  RESSOURCE_NOT_MANAGE = 1803
  VERBE_HTTP_NOT_MANAGE = 1804


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
    # Check input data
    #------------------------------------------------------------------------------------------------------------------
    action = proc {
      begin
        nul, ress_type, ress_id = @http_request_uri.split("/")

        raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "ress_type"}) if ress_type.nil? or ress_type.empty?
        raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "ress_id"}) if ress_id.nil? or ress_id.empty?

        @logger.an_event.debug "@http_request_method : #{@http_request_method}"

        @logger.an_event.debug "ress_type : #{ress_type}"
        @logger.an_event.debug "ress_id : #{ress_id}"
        case @http_request_method
          #--------------------------------------------------------------------------------------------------------------
          # GET
          #--------------------------------------------------------------------------------------------------------------
          when "GET"

            @logger.an_event.info "list #{ress_id} events from repository"
            case ress_type
              when "pre_task_over"
                if ress_id == "all"
                  tasks = @calendar.all_which_pre_tasks_over_is_complet
                  @@title_html = "All tasks which pre tasks is over"

                elsif ress_id == "today"
                  tasks = @calendar.all_which_pre_tasks_over_is_complet(Date.today)
                  @@title_html = "Today #{Date.today} tasks which pre tasks is over "

                else
                  raise Error.new(RESSOURCE_NOT_MANAGE, :values => {:ressource => ress_id})
                end

              when "tasks"
                if ["monday", "tuesday", "wednesday", "friday", "thursday", "saturday", "sunday"].include?(ress_id)
                  tasks = @calendar.all_on_date(Calendar.next_day(ress_id))
                  @@title_html = "On #{ress_id} tasks"

                elsif ress_id == "all"
                  tasks = @calendar.all
                  @@title_html = "All tasks"

                elsif ress_id == "today"
                  tasks = @calendar.all_on_date(Date.today)
                  @@title_html = "Today #{Date.today} tasks"

                elsif ress_id == "now"
                  now = Time.now
                  tasks = @calendar.all_on_time(Date.today,
                                                now.hour,
                                                now.min)
                  @@title_html = "Current tasks #{now}"

                else
                  raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "query string"}) if @http_query_string.nil?
                  query_values = Addressable::URI.parse("?#{@http_query_string}").query_values

                  case ress_id
                    when "date"
                      raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "date"}) if query_values["date"].nil? or query_values["date"].empty?
                      tasks = @calendar.all_on_date(Date.parse(query_values["date"]))
                      @@title_html = "All tasks of date #{query_values["date"]}"

                    when "hour"
                      raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "date"}) if query_values["date"].nil? or query_values["date"].empty?
                      raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "hour"}) if query_values["hour"].nil? or query_values["hour"].empty?
                      tasks = @calendar.all_on_hour(Date.parse(query_values["date"]),
                                                    query_values["hour"].to_i)
                      @@title_html = "All tasks of date #{query_values["date"]} and hour #{query_values["hour"]}"

                    when "time"
                      raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "min"}) if query_values["min"].nil? or query_values["min"].empty?
                      raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "date"}) if query_values["date"].nil? or query_values["date"].empty?
                      raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "hour"}) if query_values["hour"].nil? or query_values["hour"].empty?
                      tasks = @calendar.all_on_time(Date.parse(query_values["date"]),
                                                    query_values["hour"].to_i,
                                                    query_values["min"].to_i)

                      @@title_html = "All tasks of date #{query_values["date"]} and hour #{query_values["hour"]} and min #{query_values["min"]}"
                    when "search"
                       raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "key"}) if query_values["key"].nil? or query_values["key"].empty?
                       tasks = @calendar.one(JSON.parse(query_values["key"]))
                      @@title_html = "Search task (key : #{JSON.parse(query_values["key"])}"

                    when "execute"
                      raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "id"}) if query_values["id"].nil? or query_values["id"].empty?
                      tasks = @calendar.execute_one(query_values["id"])
                     @@title_html = "Task executed"

                    else
                      raise Error.new(RESSOURCE_NOT_MANAGE, :values => {:ressource => ress_id})

                  end
                end
              else
                raise Error.new(RESSOURCE_NOT_MANAGE, :values => {:ressource => ress_type})

            end
            @logger.an_event.info "#{tasks.size} events for #{ress_id} from repository"
          #--------------------------------------------------------------------------------------------------------------
          # POST
          #--------------------------------------------------------------------------------------------------------------
          when "POST"
            @logger.an_event.info "save events of object #{ress_id} to repository"
            @http_content = JSON.parse(@http_content, {:symbolize_names => true})
            @logger.an_event.debug "@http_content : #{@http_content}"

            case ress_type
              when "policies"
                tasks = @calendar.save_policy(ress_id, @http_content)

              else
                raise Error.new(RESSOURCE_NOT_MANAGE, :values => {:ressource => ress_type})

            end
            @logger.an_event.info "save #{tasks.size} events of object #{ress_id} to repository"
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

            raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "query string"}) if @http_query_string.nil?

            query_values = Addressable::URI.parse("?#{@http_query_string}").query_values
            raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "state"}) if query_values["state"].nil? or query_values["state"].empty?

            @http_content = JSON.parse(@http_content, {:symbolize_names => true})
            @logger.an_event.debug "@http_content : #{@http_content}"

            case ress_type
              when "tasks"
                ress_id.capitalize!

                case query_values["state"]
                  when "start"
                    @logger.an_event.info "update task #{ress_id} with START to repository"
                    @calendar.event_is_start(ress_id, @http_content)

                  when "over"
                    @logger.an_event.info "update task #{ress_id} with OVER to repository"
                    @calendar.event_is_over(ress_id, @http_content)

                  when "fail"
                    @logger.an_event.info "update task #{ress_id} with FAIL to repository"
                    @calendar.event_is_fail(ress_id, @http_content)

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
            #TODO à tester
            @logger.an_event.info "delete events of the #{ress_id} policy to repository"
            case ress_type
              when "policies"
                @calendar.delete_policy(ress_id.to_i)

              else
                raise Error.new(RESSOURCE_NOT_MANAGE, :values => {:ressource => ress_type})
            end

          else
            raise Error.new(VERBE_HTTP_NOT_MANAGE, :values => {:verb => @http_request_method})
        end

      rescue Error, Exception => e
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

          when ARGUMENT_NOT_DEFINE
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
        response.content =<<-_end_of_html_
                                <HTML>
                                 <HEAD>
                                   <title>#{@@title_html}</title>
                                </HEAD>
                                  <BODY>
                                    <h3>Short links</h3>
                                    <p>
                                      <a href="/pre_task_over/all">All tasks which pre tasks is over</a>
                                      <a href="/pre_task_over/today">Today tasks which pre tasks is over</a>
                                    </p>
                                    <p>
                                      <a href="/tasks/all">All tasks</a>
                                      <a href="/tasks/today">Today tasks</a>
                                      <a href="/tasks/now">Current tasks</a>
                                      <a href="/tasks/monday">Monday tasks</a>
                                      <a href="/tasks/tuesday">Tuesday tasks</a>
                                      <a href="/tasks/wednesday">Wednesday tasks</a>
                                      <a href="/tasks/thursday">Thursday tasks</a>
                                      <a href="/tasks/friday">Friday tasks</a>
                                      <a href="/tasks/saturday">Saturday tasks</a>
                                      <a href="/tasks/sunday">Sunday tasks</a>
                                    </p>
                                    <h3>#{@@title_html}</h3>
                                    <ul>
                                       <li>#{results.map{|r| r.to_html }.join("</li><li>")}</li>
                                    </ul>
                                  <BODY>

                                </HTML>
        _end_of_html_
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


