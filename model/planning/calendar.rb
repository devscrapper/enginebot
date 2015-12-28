require_relative 'events'
require_relative 'event'
require 'date'

module Planning

  class Calendar
    attr :events, :sem, :scrape_server_port

    def initialize(scrape_server_port)

      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
      @events = Events.new()
      @sem = Mutex.new
      @scrape_server_port = scrape_server_port
    end


    def execute_all_at(date, hour, min)


      begin
        tasks = all_on_time(date, hour, min)

      rescue Exception => e
        raise "cannot list task to execute : #{e.message}"

      else
        unless tasks.empty?
          @logger.an_event.info "ask execution #{tasks.size} tasks event at date #{date}, hour #{hour}, min #{min}: #{tasks.join(",")}"

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
          @logger.an_event.info "ask execution #{tasks.size} tasks event which pre task are over today : #{tasks.join(",")}"

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
      raise ArgumentError, date if date.nil?
      @events.on_day(date)
    end

    def all_on_hour(date, hour)
      @logger.an_event.info "list all jobs at <#{date}>, hour <#{hour}>"
      raise ArgumentError, date if date.nil?
      raise ArgumentError, hour if hour.nil?
      @events.on_hour(date, hour)
    end

    def all_on_time(date, hour, min)
      @logger.an_event.info "list all jobs at time <#{date}>, hour <#{hour}>, hour <#{min}>"

      raise ArgumentError, date if date.nil?
      raise ArgumentError, hour if hour.nil?
      raise ArgumentError, min if min.nil?
      @events.on_min(date, hour, min)
    end


    def all_which_pre_tasks_over_is_complet(date=nil)

      unless date.nil?
        start_time = Time.local(date.year, date.month, date.day)
        end_time = start_time + 23 * IceCube::ONE_HOUR - IceCube::ONE_SECOND
        @logger.an_event.info "list all jobs which pre task are over for #{date}"
      else
        @logger.an_event.info "list all jobs which pre task are over"
      end

      @events.all.keep_if { |evt, periodicity|
        !evt.pre_tasks.empty? and # possède au moins une pré task
            # selectionne les task qui s'execute pour cette >date<
            (date.nil? or (!date.nil? and !evt.periodicity.empty? and IceCube::Schedule.from_yaml(evt.periodicity).occurring_between?(start_time, end_time))) and
            evt.pre_tasks_running.empty? and # aucune pre task n'est en cours d'execution
            #permet de comparer le contenu des array afin de s'assurer qu'ils sont identiques
            (evt.pre_tasks_over & evt.pre_tasks).size == evt.pre_tasks.size # toutes les pre task sont OVER ; double controle avec running (sécurité)
      }
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
          key = {"website_label" => data_event[:website_label],
                 "policy_type" => data_event[:policy_type],
                 "date_building" => data_event[:date_building]
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


    def self.next_day(day)
      date = Date.parse(day)
      date + (date > Date.today ? 0 : 7)
    end
  end
end