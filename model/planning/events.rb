# encoding: UTF-8
require 'rubygems' # if you use RubyGems
require 'json'
require_relative 'event'
require_relative '../../lib/logging'

module Planning

  class Events
    class EventsException < StandardError
    end
    EVENTS_FILE = File.dirname(__FILE__) + "/../../data/" + File.basename(__FILE__, ".rb") + ".json"
    attr :events, :logger

    def initialize
      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
      @events = Array.new
      begin
        JSON.parse(File.read(EVENTS_FILE, {:encoding => "BOM|UTF-8:-"})).each { |evt|
          @events << Event.new(evt["key"], evt["cmd"],
                               {"state" => evt["state"],
                                "pre_tasks_over" => evt["pre_tasks_over"],
                                "pre_tasks_running" => evt["pre_tasks_running"],
                                "pre_tasks" => evt["pre_tasks"],
                                "periodicity" => evt["periodicity"],
                                "business" => evt["business"]}) #if (!evt["periodicity"].empty? and !IceCube::Schedule.from_yaml(evt["periodicity"]).next_occurrence.nil?)
        }
        @logger.an_event.info "repository events is loaded"
        @logger.an_event.debug EVENTS_FILE
      rescue Exception => e
        @logger.an_event.warn "repository events is initialize empty"
        @logger.an_event.debug e
      ensure
        @events
      end
    end

    def execute_all_at_time(date, hour, min)
      raise ArgumentError, date if date.nil?
      raise ArgumentError, hour if hour.nil?
      raise ArgumentError, min if min.nil?
      tasks = on_min(date, hour, min)

      unless tasks.empty?
        tasks.each { |evt, periodicity|

          begin
            evt.execute

          rescue Exception => e
            raise "cannot ask execution task <#{evt.cmd}> : #{e.message}"

          else
            @logger.an_event.debug "asked execution task <#{evt.cmd}>"

          end
        }
      else
        @logger.an_event.info "none task event"

      end
    end

    def execute_all_at_hour(date, hour)
      raise ArgumentError, date if date.nil?
      raise ArgumentError, hour if hour.nil?
      raise ArgumentError, load_server_port if load_server_port.nil?

      tasks = on_hour(date, hour)

      unless tasks.empty?
        tasks.each { |evt, periodicity|

          begin
            evt.execute

          rescue Exception => e
            raise "cannot ask execution task <#{evt.cmd}> : #{e.message}"

          else
            @logger.an_event.debug "asked execution task <#{evt.cmd}>"

          end
        }
      else
        @logger.an_event.info "none task event"

      end
    end

    def execute_all_which_pre_tasks_over_is_complet(date)
      raise ArgumentError, date if date.nil?

      tasks = all_which_pre_tasks_over_is_complet(date)

      unless tasks.empty?
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
        @logger.an_event.info "none task event"

      end
    end

    def all
      @events.dup
    end

    def all_on_time(date, hour, min)
      raise ArgumentError, date if date.nil?
      raise ArgumentError, hour if hour.nil?
      raise ArgumentError, min if min.nil?
      tasks = []

      tasks += on_min(date, hour, min)
      tasks
    end

    def all_on_hour(date, hour)
      raise ArgumentError, date if date.nil?
      raise ArgumentError, hour if hour.nil?


      tasks = []

      tasks += on_hour(date, hour)

      tasks
    end

    def all_on_date(date)
      raise ArgumentError, date if date.nil?


      tasks = []

      tasks += on_day(date)

      tasks
    end

    def all_which_pre_tasks_over_is_complet

      @events.dup.keep_if { |evt, periodicity|
        evt.pre_tasks_running.empty? and
            !evt.pre_tasks.empty? and
            #permet de comparer le contenu des array afin de s'assurer qu'ils sont identiques
            (evt.pre_tasks_over & evt.pre_tasks).size == evt.pre_tasks.size
      }
    end


    def save()
      begin
        events_file = File.open(EVENTS_FILE, "w+:BOM|UTF-8:-")
        events_file.sync = true
        events_file.write(JSON.pretty_generate(@events))
        events_file.close
        @logger.an_event.info "repository events saved"
      rescue Exception => e
        @logger.an_event.warn "cannot save repository events"
        raise EventsException, e
      end
    end

    def [](i)
      @events[i]
    end

    def size
      @events.size
    end

    def exist?(event)
      @events.each { |evt|
        return true if evt.key == event.key and evt.cmd == event.cmd
      } unless @events.nil?
      false
    end

    def add(event)
      event.each { |evt| @events << evt } if event.is_a?(Array)
      @events << event unless event.is_a?(Array)
      @logger.an_event.info "save event <#{event.cmd}> for <#{event.business["website_label"]}> to repository"
    end

    def delete(event)
      @events.delete_if { |e| e.key["policy_id"] == event.key["policy_id"] and e.cmd == event.cmd }
      @logger.an_event.info "event #{event.cmd} for #{event.business["website_label"]} deleted from repository"
    end


    def execute_one(event)
      @events.each { |evt|
        evt.execute if evt.key == event.key and evt.cmd == event.cmd
      } unless @events.nil?
    end

    def on_hour(date, hour)
      start_time = Time.local(date.year, date.month, date.day, hour, 0, 0)
      on_period(start_time, start_time + IceCube::ONE_HOUR)

    end

    def on_min(date, hour, min)
      start_time = Time.local(date.year, date.month, date.day, hour, min, 0)
      on_period(start_time, start_time + IceCube::ONE_MINUTE)
    end

    def on_day(date)
      start_time = Time.local(date.year, date.month, date.day)
      on_period(start_time, start_time + 23 * IceCube::ONE_HOUR)
    end

    def on_week(date)
      start_time = Time.local(date.year, date.month, date.day)
      on_period(start_time, start_time + IceCube::ONE_WEEK)
    end

    def on_period(start_time, end_time)
      selected_events = []
      @events.each { |evt|
        unless evt.periodicity.empty?
          occurences = IceCube::Schedule.from_yaml(evt.periodicity).occurrences_between(start_time, end_time - IceCube::ONE_SECOND) # end_time exclue
          selected_events << [evt, occurences] unless occurences.empty?
        end
      }
      selected_events
    end


    def display_cmd()
      i = 1
      @events.each { |evt|
        p "#{i} -> website : #{evt.business["website_label"]}, cmd #{evt.cmd}, key : #{evt.key}"
        i +=1
      }
    end

    def display_website()
      p "websites : "
      websites = {}
      @events.each { |evt| websites[evt.key["website_id"]] = evt.business["website_label"] unless evt.key["website_id"].nil? }
      websites.each_pair { |key, value| p "#{key} -> website : #{value}" }
    end

    def display_policy()
      p "policies : "
      policies = {}
      @events.each { |evt| policies[evt.key["policy_id"]] = evt.business["website_label"] unless evt.key["policy_id"].nil? }
      policies.each_pair { |key, value| p "#{key} -> website : #{value}" }
    end

    def display_objective()
      p "objectives : "
      objectives = {}
      @events.each { |evt| objectives[evt.key["objective_id"]] = evt.business["website_label"] unless evt.key["objective_id"].nil? }
      objectives.each_pair { |key, value| p "#{key} -> objective : #{value}" }
    end

    def pre_tasks_over(task_name, key)
      # key = {"policy_id" => data_event["policy_id"]}

      # ou bien

      # key = {"website_label" => data_event["website_label"],
      #        "policy_type" => data_event["policy_type"]}
      # dans events.json
      # {
      #     "key" : {
      #     "policy_id" : 6
      # },
      #     "cmd" : "Building_landing_pages_direct",
      #     "periodicity" : "---\n:start_date: 2015-11-16 00:00:00.000000000 +01:00\n:end_time: 2015-11-24 00:00:00.000000000 +01:00\n:rrules:\n- :validations: {}\n  :rule_type: IceCube::DailyRule\n  :interval: 1\n:exrules: []\n:rtimes: []\n:extimes: []\n",
      #     "business" : {
      #     "website_label" : "epilation",
      #     "website_id" : 1,
      #     "policy_id" : 6,
      #     "policy_type" : "traffic"
      # }
      # }

      @events.each { |evt|
        if (!key["policy_id"].nil? and evt.key["policy_id"] == key["policy_id"]) or
            (evt.business["website_label"] == key["website_label"] and evt.business["policy_type"] == key["policy_type"])

          # remarques : une commande ne peut pas être pre task d'elle même, donc les 2 actions sont exclusives
          if (evt.cmd == task_name.to_s)
            #qd une commande est terminée, on remet à l'etat initial les pre_task de la command
            evt.pre_tasks_over = []
            evt.state = Event::OVER
          else
            if evt.pre_tasks.include?(task_name.to_s)
              # deplace les task terminées de task_running vers les task_over de chaque commande (task)
              evt.pre_tasks_over << task_name.to_s
              evt.pre_tasks_running.delete(task_name.to_s)
            end
          end
        end
      } unless @events.nil?
    end

    def pre_tasks_running(task_name, key)
      # key = {"policy_id" => data_event["policy_id"]}

      # ou bien

      # key = {"website_label" => data_event["website_label"],
      #        "policy_type" => data_event["policy_type"]}
      # dans events.json
      # {
      #     "key" : {
      #     "policy_id" : 6
      # },
      #     "cmd" : "Building_landing_pages_direct",
      #     "periodicity" : "---\n:start_date: 2015-11-16 00:00:00.000000000 +01:00\n:end_time: 2015-11-24 00:00:00.000000000 +01:00\n:rrules:\n- :validations: {}\n  :rule_type: IceCube::DailyRule\n  :interval: 1\n:exrules: []\n:rtimes: []\n:extimes: []\n",
      #     "business" : {
      #     "website_label" : "epilation",
      #     "website_id" : 1,
      #     "policy_id" : 6,
      #     "policy_type" : "traffic"
      # }
      # }

      @events.each { |evt|
        evt.state = Event::START if evt.cmd == task_name.to_s

        if (!key["policy_id"].nil? and evt.key["policy_id"] == key["policy_id"]) or
            (evt.business["website_label"] == key["website_label"] and evt.business["policy_type"] == key["policy_type"]) and
                evt.pre_tasks.include?(task_name.to_s)

          evt.pre_tasks_running << task_name.to_s

        end
      } unless @events.nil?

    end

  end
end