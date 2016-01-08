require_relative '../../lib/logging'
require_relative 'event'
require 'date'
require 'json'


module Planning

  class Calendar

    EVENTS_FILE = File.dirname(__FILE__) + "/../../data/" + File.basename(__FILE__, ".rb") + ".yml"

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

    def css
      <<-_end_of_html_

@import url(http://fonts.googleapis.com/css?family=Droid+Sans:400,700|Droid+Serif:400,700);
* {
  margin: 0;
  padding: 0;
}

html, body {
  height: 100%;
width: 100%;
overflow-y: auto;
}

body {
  text-align: center;
  background-color: #5d4660;
  *zoom: 2;
  font-family: 'Droid Sans', sans-serif;

}

.wrap {
 // width: 100%;
  margin: 0 auto;
  text-align: left;
  color: #989A8F;
overflow:auto;

}

.table {
 // background-color: #ffffff;
  height: 270px;
  width: 100%;
  margin-top: 10px;

}

ul li {
  float: left;
  width: 250px;
  text-align: center;
  border-left: 1px solid #DDDCD8;
     background-color: #ffffff;

}

.top {
  background-color: #EAE9E4;
  height: 50px;
  margin-top: 0px;
}
.title h3{
  background-color: #EAE9E4;
  height: 50px;
  margin-top: 20px;
}
.day h3{
  background-color: #EAE9E4;
  height: 50px;
  margin-top: 20px;
}
.top h5 {
  padding-top: 20px;
}

.circle {
  width: 60px;
  height: 60px;
  border-radius: 60px;
  font-size: 20px;
  color: #fff;
  line-height: 60px;
  text-align: center;
  background: #989A8F;
  margin-left: 100px;
  margin-top: 10px;
}

.bottom {
  margin-top: 50px;
  height: 300px;
}
.bottom p {

  font-size: 13px;
  font-family: 'Droid Serif', sans-serif;
  padding: 10px;
}
.bottom p  {
      font-family: 'Droid Sans', sans-serif;
}
.bottom p span {
      font-family: 'Droid Sans', sans-serif;
      font-weight: bold;
}

.sign {
  margin-top: 50px;

}
.sign .button {
  border: 2px solid #989A8F;
  padding: 10px 40px;
  -webkit-border-radius: 6px;
  -moz-border-radius: 6px;
  border-radius: 6px;
  color: #989A8F;
  font-size: 14px;
  text-decoration: none;
  vertical-align: middle;
  font-size: 17px;
}
.shortcut {
  margin-top: 35px;

}
.shortcut .button {
  border: 1px solid #989A8F;
  padding: 10px 40px;
  -webkit-border-radius: 6px;
  -moz-border-radius: 6px;
  border-radius: 6px;
  color: #FFFFFF;
  font-size: 14px;
  text-decoration: none;
  vertical-align: middle;
  font-size: 17px;
  background-color: Indigo    ;
}
.purple {
  background-color: #5D4660;
}

.white {
  color: #FFFFFF;
}

.red {
  background-color: FireBrick;
}

.green {
  background-color: DarkGreen;
}

.pink {
  background-color: #BC9B94;
}

      _end_of_html_
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
        @logger.an_event.debug "cannot delete policy #{policy_id} events in calendar : #{e.message}"
        raise "cannot delete policy #{policy_id} events in calendar : #{e.message}"

      else
        @logger.an_event.debug "delete policy #{policy_id} events in calendar"

      end
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
      res.sort_by { |date, events| date }.each { |date, events|
        str += "<div class='day'><h3>#{date}</h3></div>" + '<div class="wrap"><div class="table"><ul>'
        str += tri(events).map { |e| e.to_html }.join
        str += '</ul>        </div>        </div>'
      }
      str + ""
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

    # enregister les Events issus d'une policy ou d'un objective dans le calendar
    # retourne Array contenant les Events
    # retourne Array vide si pb
    def register(object, data_event)
      raise ArgumentError, object if object.nil? or object.empty?
      raise ArgumentError, data_event if data_event.nil? or data_event.empty?
      begin
        @logger.an_event.debug "register object <#{object}> data_event #{data_event}"
        require_relative "object2event/#{object.downcase}"
        events = eval(object.capitalize!).new(data_event).to_event

        @sem.synchronize {
          events.each { |e|
            delete_event(e)
            add(e)
          }
          save
        }

      rescue Exception => e
        @logger.an_event.debug "cannot register #{events.size} events #{events} in calendar"
        raise "cannot register events object #{object} in calendar"
        []

      else
        @logger.an_event.debug "register #{events.size} events #{events} in calendar"
        events

      end

    end

    private


    def add(event)
      event.each { |evt| @events << evt } if event.is_a?(Array)
      @events << event unless event.is_a?(Array)
    end

    def delete_event(event)

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

    # ordonne les events en fonction du cirtère pre_task :
    # si un event a des pre task il est placé derriere ses pre task
    def tri(arr)
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
  end
end