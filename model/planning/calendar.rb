require_relative 'events'
require_relative 'event'


module Planning

  class Calendar
    attr :events, :sem, :scrape_server_port

    def initialize(scrape_server_port)

      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
      @events = Events.new()
      @sem = Mutex.new
      @scrape_server_port = scrape_server_port
    end

    def execute_all(data_event)
      # exclusivement utiliser par le calendar_client.rb pour tester
      if !data_event["date"].nil? and !data_event["hour"].nil?
        @logger.an_event.info "ask execution all jobs at date #{data_event["date"]}, hour #{data_event["hour"]}"
        @events.execute_all_at_time(data_event["date"], data_event["hour"])
      else
        @logger.an_event.error "cannot execute events because start time is not define"
        @logger.an_event.debug "date #{data_event["date"]}"
        @logger.an_event.debug "date #{data_event["hour"]}"
      end
    end

    def execute_all_at(date, hour, min)


      begin
        tasks = all_on_time(date, hour, min)

      rescue Exception => e
          raise "cannot list task to execute : #{e.message}"

      else
        unless tasks.empty?
          @logger.an_event.info "ask execution #{tasks.size} tasks event at date #{date}, hour #{hour}, min #{min}"

          tasks.each { |evt, periodicity|
            begin
              if evt.state != Event::START
                evt.execute
              else
                @logger.an_event.warn "task <#{evt.cmd}> already running"
              end

            rescue Exception => e
              raise "cannot ask execution task <#{evt.cmd}> : #{e.message}"

            else
              @logger.an_event.info "asked execution task <#{evt.cmd}>"

            end
          }
        else
          @logger.an_event.info "none task event to execute"

        end
      end


    end

    def execute_all_which_pre_tasks_over_is_complet(date)
      begin
        tasks = all_which_pre_tasks_over_is_complet(date)

      rescue Exception => e
        raise "cannot list task to execute : #{e.message}"

      else

        unless tasks.empty?
          @logger.an_event.info "ask execution #{tasks.size} tasks event which pre task are over today"

          tasks.each { |evt, periodicity|
            begin
              if evt.state != Event::START
                evt.execute
              else
                @logger.an_event.warn "task <#{evt.cmd}> already running"
              end

            rescue Exception => e
              raise "cannot ask execution task <#{evt.cmd}> : #{e.message}"

            else
              @logger.an_event.info "asked execution task <#{evt.cmd}>"

            end
          }
        else
          @logger.an_event.info "none task event to execute  which pre task are over today"

        end
      end

    end

    def all
      @logger.an_event.info "list all jobs"
      @events.all
    end

    def all_on_date(date)
      @logger.an_event.info "list all jobs at date <#{date}>"
      @events.all_on_date(date)
    end

    def all_on_hour(date, hour)
      @logger.an_event.info "list all jobs at <#{date}>, hour <#{hour}>"
      @events.all_on_hour(date, hour)
    end

    def all_on_time(date, hour, min)
      @logger.an_event.info "list all jobs at time <#{date}>, hour <#{hour}>, hour <#{min}>"
      @events.all_on_time(date, hour, min)
    end

    def all_which_pre_tasks_over_is_complet(date)
      @logger.an_event.info "list all jobs which pre task are over"
      @events.all_which_pre_tasks_over_is_complet(date)
    end

    def save_object(object, data_event)
      begin
        @logger.an_event.debug "object <#{object}> data_event #{data_event}"
        require_relative "object2event/#{object.downcase}"
        events = eval(object).new(data_event).to_event

        @sem.synchronize {
          events.each { |e|
            if @events.exist?(e)
              @events.delete(e)
            end
            @events.add(e)
          }
          @events.save
        }
      rescue Exception => e
        @logger.an_event.debug e
        raise "cannot save object #{object} into repository"

      else
        @logger.an_event.debug "save events #{events}"
        events
      end

    end

    def delete_object(object, data_event)
      begin
        require_relative "object2event/#{object.downcase}"
        events = eval(object).new(data_event).to_event
        @logger.an_event.debug "events #{events}"
        @sem.synchronize {
          events.each { |e|
            @events.delete(e)
          }
          @events.save
        }
      rescue Exception => e
        @logger.an_event.debug e
        raise "cannot delete object #{object} from repository"

      end
    end

    def event_is_over(task_name, data_event)
      begin

        unless data_event[:policy_id].nil?
          # lors que event de fin de tache sont émis par task_list alors policy_id est présent
          key = {"policy_id" => data_event[:policy_id]}
        else
          # lorsque les fins de taches sont émis par flow_list alors policy_id est absent car il n'y a pas de données
          # échangées, seule le nom du fichier est porteur de données donc on s'appuie sur les données du nom
          # du Flow pour identifier la policy : policy_type, website_label, date_building
          key = {"website_label" => data_event["website_label"],
                 "policy_type" => data_event["policy_type"],
                 "date_building" => data_event["date_building"]
          }
        end
        @sem.synchronize {
          @events.pre_tasks_over(task_name, key)
          @events.save
        }
      rescue Exception => e
        raise "cannot update tasks #{key} with pre_task #{task_name} : #{e.message}"

      else
        @logger.an_event.debug "update tasks #{key} with pre_task #{task_name}"
      end
    end

    def event_is_start(task_name, data_event)
      begin

        unless data_event[:policy_id].nil?
          # lors que event de fin de tache sont émis par task_list alors policy_id est présent
          key = {"policy_id" => data_event[:policy_id]}
        else
          # lorsque les fins de taches sont émis par flow_list alors policy_id est absent car il n'y a pas de données
          # échangées, seule le nom du fichier est porteur de données donc on s'appuie sur les données du nom
          # du Flow pour identifier la policy : policy_type, website_label, date_building
          key = {"website_label" => data_event["website_label"],
                 "policy_type" => data_event["policy_type"],
                 "date_building" => data_event["date_building"]
          }
        end
        @sem.synchronize {
          @events.pre_tasks_running(task_name, key)
          @events.save
        }
      rescue Exception => e
        raise "cannot update tasks #{key} with pre_task #{task_name} : #{e.message}"

      else
        @logger.an_event.debug "update tasks #{key} with pre_task #{task_name}"
      end
    end
  end
end