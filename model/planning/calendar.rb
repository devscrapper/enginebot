require_relative '../../lib/logging'
require_relative '../../lib/parameter'
require_relative 'event'
require 'date'
require 'json'


module Planning

  class Calendar

    EVENTS_FILE = File.dirname(__FILE__) + "/../../data/" + File.basename(__FILE__, ".rb") + ".yml"
    CALENDAR_CSS = File.dirname(__FILE__) + "/" + File.basename(__FILE__, ".rb") + ".css"
    attr :events,
         :sem,
         :logger


    def initialize(log=nil)

      @logger = log || Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
      @events = Array.new
      @sem = Mutex.new

      begin
        @logger.an_event.debug "calendar file : #{EVENTS_FILE}"

        @events = YAML::load(File.open(EVENTS_FILE, {:encoding => "BOM|UTF-8:-"}))

      rescue Exception => e
        @logger.an_event.warn "calendar empty : #{e.message}"

      else
        @logger.an_event.info "events calendar loaded"

      ensure

      end
    end

    # selection d'UN objet Event en fonction des critères :
    # event_id (tous les events)
    # ou
    # policy_id & task_label (task hebdo ou mensuelle ayant un event recurrent dans le calendar)
    # ou
    # policy_id & task_label & date_building  (task quotidienne ayant plusieurs event dans le calendar)

    def [](options)
      select(options)
    end

    # retourne un array copie de tous les events
    def all_events
      @events.dup
    end

    # retourne un Array contenant les Event de la date, array vide sinon
    def all_events_on_date(date)
      raise ArgumentError, date if date.nil?
      start_time = Time.local(date.year, date.month, date.day)
      on_period(start_time, start_time + 23 * IceCube::ONE_HOUR)
    end

    # retourne un Array contenant les Event de la date et heure, array vide sinon
    def all_events_on_hour(date, hour)
      raise ArgumentError, date if date.nil?
      raise ArgumentError, hour if hour.nil?
      start_time = Time.local(date.year, date.month, date.day, hour, 0, 0)
      on_period(start_time, start_time + IceCube::ONE_HOUR)
    end

    # retourne un Array contenant les Event de la date et heure et minute, array vide sinon
    def all_events_on_time(date, hour, min)
      raise ArgumentError, date if date.nil?
      raise ArgumentError, hour if hour.nil?
      raise ArgumentError, min if min.nil?
      start_time = Time.local(date.year, date.month, date.day, hour, min, 0)
      on_period(start_time, start_time + IceCube::ONE_MINUTE)
    end

    # retourn an Array contenant tous les events en cours d'exécution
    def all_events_running
      all_events.keep_if { |evt| evt.is_started? }
    end

    # retourne un Array contenant les event (ou ceux du jour) ayant des pre_task qui sont toutes  terminées
    def all_events_which_all_pre_tasks_are_over(date=nil)

      unless date.nil?
        events = all_events_on_date(date)
      else
        events = all_events
      end

      events.keep_if { |evt| evt.has_pre_tasks? and !evt.has_pre_tasks_running? and evt.all_pre_tasks_over? }
    end

    #supprimer tous events produit par les objectives d'un policy
    def delete_objectives(policy_id, building_date)
      raise ArgumentError, policy_id if policy_id.nil?
      @events.delete_if { |e| e.is_objective? and e.key[:policy_id] == policy_id and e.key[:building_date] == building_date}
    end

    # supprimer tous les events d'une policy => policy_id (integer)
    # si obj recherché est absent => RAS ; pas besoin de tester existance de obj.
    def delete_policy(policy_id)
      raise ArgumentError, policy_id if policy_id.nil?
      begin
        @sem.synchronize {
          @events.delete_if { |e| e.key[:policy_id] == policy_id }
          save
        }

      rescue Exception => e
        @logger.an_event.debug "cannot delete events policy #{policy_id} in calendar : #{e.message}"
        raise "cannot delete events policy #{policy_id} in calendar : #{e.message}"

      else
        @logger.an_event.debug "delete events policy #{policy_id} in calendar"

      end
    end


    def event_is_over(event_id)
      raise ArgumentError, event_id if event_id.nil?
      begin
        @sem.synchronize {
          evt = select({:event_id => event_id})
          evt.is_finished
          pre_tasks_over(evt)
          save
        }
      rescue Exception => e
        @logger.an_event.debug "cannot set event #{event_id} is over  : #{e.message}"
        raise "cannot set event #{event_id} is over  : #{e.message}"

      else
        @logger.an_event.debug "set event #{event_id} is over"

      end
    end

    def event_is_start(event_id)
      raise ArgumentError, event_id if event_id.nil?
      begin

        @sem.synchronize {
          evt = select({:event_id => event_id})
          evt.is_started
          pre_tasks_running(evt)
          save
        }
      rescue Exception => e
        @logger.an_event.debug "cannot set event #{event_id} is start  : #{e.message}"
        raise "cannot set event #{event_id} is start  : #{e.message}"

      else
        @logger.an_event.debug "set event #{event_id} is start"
      end
    end

    def event_is_fail(event_id)
      raise ArgumentError, event_id if event_id.nil?
      begin

        @sem.synchronize {
          evt = select({:event_id => event_id})
          evt.failed
          pre_tasks_fail(evt)
          save
        }
      rescue Exception => e
        @logger.an_event.debug "cannot set event #{event_id} is failed  : #{e.message}"
        raise "cannot set event #{event_id} is failed  : #{e.message}"

      else
        @logger.an_event.debug "set event #{event_id} failed"
      end
    end

    def execute_all_events_at(date, hour, min)


      begin
        tasks = all_events_on_time(date, hour, min)

      rescue Exception => e
        @logger.an_event.debug "cannot list events to execute : #{e.message}"
        raise "cannot list events to execute : #{e.message}"

      else
        unless tasks.empty?

          execute_tasks(tasks)

        else
          @logger.an_event.info "none event to execute"

        end
      end


    end

    # permet l'execution de tous les events qui ont des pré_task qui sont terminés
    def execute_all_events_which_all_pre_tasks_are_over(date)

      begin
        tasks = all_events_which_all_pre_tasks_are_over(date)

      rescue Exception => e
        @logger.an_event.debug "cannot list events to execute : #{e.message}"
        raise "cannot list events to execute : #{e.message}"

      else

        unless tasks.empty?

          execute_tasks(tasks)

        else
          @logger.an_event.info "none event to execute the day #{date} which pre task are over"

        end
      end

    end


    # permet l'execution d'un event en fonction de son id
    def execute_one(event_id)

      begin
        events = select({:event_id => event_id})

      rescue Exception => e
        @logger.an_event.debug "cannot list events to execute : #{e.message}"
        raise "cannot list events to execute : #{e.message}"

      else
        if !events.nil?

          execute_tasks([events])
          [events]

        else
          @logger.an_event.info "none task event to execute with id #{event_id}"
          []

        end


      end

    end

    # retourne le jour suivant day
    def self.next_day(day)
      raise ArgumentError, day if day.nil? or day.empty?

      date = Date.parse(day)
      date + (date > Date.today ? 0 : 7)
    end

    # enregister les Events issus d'une policy  dans le calendar
    # retourne Array contenant les Events
    # retourne Array vide si pb
    def register_policy(policy, data_event)
      raise ArgumentError, policy if policy.nil? or policy.empty?
      raise ArgumentError, data_event if data_event.nil? or data_event.empty?
      begin
        @logger.an_event.debug "delete policy <#{policy}:#{data_event[:policy_id]}>"

        delete_policy(data_event[:policy_id])

        @logger.an_event.debug "register policy <#{policy}> data_event #{data_event}"
        require_relative "object2event/#{policy.downcase}"
        events = eval(policy.capitalize!).new(data_event).to_event

        @logger.an_event.debug "count #{events.size} events from policy #{policy}"

        @sem.synchronize {
          events.each { |e|
            add(e)
            @logger.an_event.debug "add #{e} to calendar"
          }
          save
          @logger.an_event.debug "save calendar"
        }

      rescue Exception => e
        @logger.an_event.debug "cannot register events policy #{policy} in calendar : #{e.message}"
        raise "cannot register events policy #{policy} in calendar : #{e.message}"
        []

      else
        @logger.an_event.debug "register #{events.size} events in calendar"
        events

      end

    end

    # enregister les Events issus d'un objective dans le calendar
    # retourne Array contenant les Events
    # retourne Array vide si pb
    def register_objective(object, data_event)
      raise ArgumentError, object if object.nil? or object.empty?
      raise ArgumentError, data_event if data_event.nil? or data_event.empty?
      begin
        @logger.an_event.debug "register object <#{object}> data_event #{data_event}"
        require_relative "object2event/#{object.downcase}"
        events = eval(object.capitalize!).new(data_event).to_event

        @sem.synchronize {
          #suppression des objective existant de la policy : policy_id
          delete_objectives(data_event[:policy_id], data_event[:building_date])

          events.each { |e|
            add(e)
          }
          save
        }

      rescue Exception => e
        @logger.an_event.debug "cannot register #{events.size} events #{events} in calendar : #{e.message}"
        raise "cannot register events object #{object} in calendar : #{e.message}"
        []

      else
        @logger.an_event.debug "register #{events.size} events #{events} in calendar"
        events

      end

    end

    def to_html(results, title)
      <<-_end_of_html_
    <HTML>
     <HEAD>
        <style>
        #{css}
        </style>
       <title>#{title}</title>
    </HEAD>
      <BODY>
        #{header(title)}
      #{display(results)}
      </BODY>
    </HTML>
      _end_of_html_
    end

    private


    def add(event)
      @events += event if event.is_a?(Array)
      @events << event unless event.is_a?(Array)
    end

    def css
      <<-_end_of_html_
#{File.read(CALENDAR_CSS)}
      _end_of_html_
    end

    def delete_event(event)
      @events.delete_if { |e| e.id == event.id }
    end

    def display(events=@events)
      res = {}
      events.each { |evt|
        date = Date.parse(evt.periodicity.first.to_s).to_s
        if res[date].nil?
          res.merge!({date => [evt]})
        else
          res[date] << evt
        end
      }
      str = ""

      res.sort_by { |date| date }.each { |date, events|
        events_with_pre_task = sort_by_pre_task(events.select { |e| e.has_pre_tasks? })
        events_with_start_time = sort_by_start_time(events.select { |e| !e.has_pre_tasks? })
        str += "<div class='day'><h3>#{date}</h3></div>" + '<div class="wrap"><div class="table"><ul>'
        #     str += sort_by_pre_task(events).map { |e| e.to_html }.join
        str += (events_with_start_time + events_with_pre_task).map { |e| e.to_html }.join
        str += '</ul></div></div>'
      }
      str + ""
    end

    # execute tous les events
    def execute_tasks(events)

      events.each { |evt|
        begin
          evt.execute

        rescue Exception => e
          raise "cannot execute event <#{evt}> : #{e.message}"

        else
          @logger.an_event.info "execute event <#{evt}>"

        end
      }

    end

    def header(title)
      <<-_end_of_html_
    <p>
      <div class="shortcut">
      <a class="button" href="/tasks/all">All tasks</a>
      <a class="button" href="/tasks/today">Today tasks</a>
      <a class="button" href="/tasks/running">Running tasks</a>
      </div>
    </p>
    <p>
      <div class="shortcut">
      <a class="button" href="/tasks/monday">Monday tasks</a>
      <a class="button" href="/tasks/tuesday">Tuesday tasks</a>
      <a class="button" href="/tasks/wednesday">Wednesday tasks</a>
      <a class="button" href="/tasks/thursday">Thursday tasks</a>
      <a class="button" href="/tasks/friday">Friday tasks</a>
      <a class="button" href="/tasks/saturday">Saturday tasks</a>
      <a class="button" href="/tasks/sunday">Sunday tasks</a>
    </p>
    </div>
    <div class='title'><h3>#{title}</h3></div>
      _end_of_html_

    end


    # retourne un nouvel Array contenant les event sélectionné
    # retourne un Array vide si aucun event satisfait les critères
    def on_period(start_time, end_time) # end_time exclue
      @events.select { |evt| !evt.periodicity.occurrences_between(start_time, end_time - IceCube::ONE_SECOND).empty? }
    end

    # supprime de pre_tasks_running l'event pour tous les events dont event est pre_task
    def pre_tasks_fail(event)
      @events.map! { |evt|
        evt.delete_pre_task_running(event) if evt.has_pre_task?(event)
        evt
      }
    end

    # affecte le pre_tasks_over de l'event pour tous les events dont event est pre_task
    def pre_tasks_over(event)
      @events.map! { |evt|
        evt.add_pre_task_over(event) if evt.has_pre_task?(event)
        evt
      }
    end

    # affecte le pre_tasks_running de l'event pour tous les events dont event est pre_task
    def pre_tasks_running(event)
      @events.map! { |evt|
        evt.add_pre_task_running(event) if evt.has_pre_task?(event)
        evt
      }
    end

    def save
      events_file = File.open(EVENTS_FILE, "w+:BOM|UTF-8:-")
      events_file.sync = true
      events_file.write(@events.to_yaml)
      events_file.close
    end

    # selection d'UN objet Event en fonction des critères :
    # event_id (tous les events)
    # ou
    # policy_id & task_label (task hebdo ou mensuelle ayant un event recurrent dans le calendar)
    # ou
    # policy_id & task_label & building_date  (task quotidienne ayant plusieurs event dans le calendar)
    # si pas trouvé renvoie nil
    # si trouvé renvoie l'event
    def select(options)
      event_id = options.fetch(:event_id, nil)
      policy_id = options.fetch(:policy_id, nil)
      task_label = options.fetch(:task_label, nil)
      building_date = options.fetch(:building_date, nil)
      events = @events.select { |evt|
        (!event_id.nil? and evt.id == event_id) or
            (!policy_id.nil? and !task_label.nil? and !building_date.nil? and policy_id == evt.policy_id and task_label == evt.label and building_date == evt.building_date) or
            (!policy_id.nil? and !task_label.nil? and policy_id == evt.policy_id and task_label == evt.label)
      }
      events.empty? ? nil : events[0]
    end


    # ordonne les events en fonction du critère pre_task :
    # si un event a des pre task il est placé derriere ses pre task
    def sort(arr)
      begin
        i = 0
        while i < arr.size-1
          j = i + 1
          while j < arr.size
            if arr[i].has_pre_task?(arr[j]) or !arr[j].has_pre_tasks?
              tmp = arr[i]
              arr[i] = arr[j]
              arr[j] = tmp
            end
            j +=1
          end
          i +=1
        end
      end
      arr
    end

    # ordonne les events en fonction dun critère passé par papramètre (Bloc)
    def sort_by(arr, &bloc)
      begin
        i = 0
        while i < arr.size-1
          j = i + 1
          while j < arr.size
            if yield(arr[i], arr[j])
              tmp = arr[i]
              arr[i] = arr[j]
              arr[j] = tmp
            end
            j +=1
          end
          i +=1
        end
      end
      arr
    end

    def sort_by_pre_task(arr)
      sort_by(arr) { |e, f| e.has_pre_task?(f) or !f.has_pre_tasks? }
    end

    def sort_by_start_time(arr)
      sort_by(arr) { |e, f| f.is_before?(e) }
    end
  end
end