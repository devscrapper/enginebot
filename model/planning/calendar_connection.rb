require_relative "event"
require_relative "events"

module Planning
  class CalendarConnection < EventMachine::Connection
    include EM::P::ObjectProtocol


    attr :calendar, # repository events
         :logger


    def initialize(logger, calendar)
      @calendar = calendar
      @logger = logger
    end

    def receive_object data

      begin

        context = []
        object = data["object"]
        cmd = data["cmd"]
        data_cmd = data["data"]
        context << object << cmd

        @logger.ndc context
        @logger.an_event.debug "object <#{object}>"
        @logger.an_event.debug "cmd <#{cmd}>"
        @logger.an_event.debug "data cmd <#{data_cmd}>"
        @logger.an_event.debug "context <#{context}>"

          case cmd
          when Event::SAVE
            @logger.an_event.info "save events of the #{object} to repository"
            @calendar.save_object(object, data_cmd)
          when Event::DELETE
            @logger.an_event.info "delete events of the #{object} to repository"
            @calendar.delete_object(object, data_cmd)
          when Event::START
            task_name = object
            @logger.an_event.info "event #{task_name} is started"
            @calendar.event_is_start(task_name, data_cmd)
          when Event::OVER
            task_name = object
            @logger.an_event.info "event #{task_name} is over"
            @calendar.event_is_over(task_name, data_cmd)
            now = Time.now
            @calendar.execute_all_which_pre_tasks_over_is_complet(task_name,Date.new(now.year, now.month, now.day))
          else
            @logger.an_event.error "cmd #{cmd} is unknown"
        end
      rescue Exception => e
        @logger.an_event.error "cannot execute cmd <#{cmd}> : #{e.message}"

        data = {:state => :ko, :error => e}

      else
        data = {:state => :ok}

      ensure
        send_object data
         close_connection_after_writing

      end

    end


  end
end