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
                                "business" => evt["business"]},
                               evt["id"])
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


    def [](i)
      @events[i]
    end


    def add(event)
      event.each { |evt| @events << evt } if event.is_a?(Array)
      @events << event unless event.is_a?(Array)
      @logger.an_event.info "save event <#{event.cmd}> for <#{event.business["website_label"]}> to repository"
    end

    def all
      @events.dup
    end

    def delete(event)
      @events.delete_if { |e| e.key["policy_id"] == event.key["policy_id"] and e.cmd == event.cmd }
      @logger.an_event.info "event #{event.cmd} for #{event.business["website_label"]} deleted from repository"
    end

    def delete_policy(policy_id)
      @events.delete_if { |e| e.key["policy_id"] == policy_id }

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

    def execute_one(event)
      @events.each { |evt|
        evt.execute if evt.key == event.key and evt.cmd == event.cmd
      } unless @events.nil?
    end

    def exist?(event)
      @events.each { |evt|
        return true if evt.key == event.key and evt.cmd == event.cmd
      } unless @events.nil?
      false
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
          selected_events << evt unless occurences.empty?
        end
      }
      selected_events
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
        if (!key["policy_id"].nil? and evt.key["policy_id"] == key["policy_id"]) or #TODO ne passer que la policy et pas toute la key car pas nécessaire
            (evt.business["website_label"] == key["website_label"] and evt.business["policy_type"] == key["policy_type"]) #TODOsupprimer le cas de test sans policy_id

          # remarques : une commande ne peut pas être pre task d'elle même, donc les 2 actions sont exclusives
          if (evt.cmd == task_name.to_s)
            #qd une commande est terminée, on remet à l'etat initial les pre_task de la command
            evt.pre_tasks_over = []

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

        if (!key["policy_id"].nil? and evt.key["policy_id"] == key["policy_id"]) or #TODO ne passer que la policy et pas toute la key car pas nécessaire
            (evt.business["website_label"] == key["website_label"] and evt.business["policy_type"] == key["policy_type"]) and
                evt.pre_tasks.include?(task_name.to_s)

          evt.pre_tasks_running << task_name.to_s

        end
      } unless @events.nil?

    end

    def save
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

    def size
      @events.size
    end

    def update_state(key, state)
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

        evt.state = state if (!key["policy_id"].nil? and
            evt.key["policy_id"] == key["policy_id"] and
            evt.key["task"] == key["task"] and
            (key["building_date"].nil? or
                !key["building_date"].nil? and evt.key["building_date"] == key["building_date"])) \
        or
            (evt.business["website_label"] == key["website_label"] and
                evt.business["policy_type"] == key["policy_type"] and
                evt.key["task"] == key["task"] and
                (key["building_date"].nil? or
                    !key["building_date"].nil? and evt.key["building_date"] == key["building_date"]))
      }

    end
  end
end