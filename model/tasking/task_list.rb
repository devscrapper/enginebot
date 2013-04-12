require_relative '../building/objectives'
require_relative '../building/chosens'
require_relative '../building/visits'
require 'json'

module Tasking
  class Tasklist
    class TasklistException < StandardError;
    end
    class TasklistArgumentException < ArgumentError;
    end
    include Building

    attr :data, :logger

    def initialize(data)
      @data = data
      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
    end

    #--------------------------------------------------------------------------------------
    # OBJECTIVE
    #--------------------------------------------------------------------------------------
    def Building_objectives()
      label = @data["label"]
      date_building = @data["date_building"]
      business = @data["data"]
      execute { Objectives.new.Building_objectives(label,
                                          date_building,
                                          is_nil_or_empty? { business["change_count_visits_percent"] }.to_i,
                                          is_nil_or_empty? { business["change_bounce_visits_percent"] }.to_i,
                                          is_nil_or_empty? { business["direct_medium_percent"] }.to_i,
                                          is_nil_or_empty? { business["organic_medium_percent"] }.to_i,
                                          is_nil_or_empty? { business["referral_medium_percent"] }.to_i,
                                          is_nil_or_empty? { business["policy_id"] }.to_i,
                                          is_nil_or_empty? { business["website_id"] }.to_i,
                                          business["account_ga"])
      }
    end

    #--------------------------------------------------------------------------------------
    # CHOSEN
    #--------------------------------------------------------------------------------------
    def Choosing_landing_pages()
      label = @data["label"]
      date_building = @data["date_building"]
      business = @data["data"]

      execute { Chosens.new.Choosing_landing_pages(label, date_building,
                                                   is_nil_or_empty? { business["direct_medium_percent"] }.to_i,
                                                   is_nil_or_empty? { business["organic_medium_percent"] }.to_i,
                                                   is_nil_or_empty? { business["referral_medium_percent"] }.to_i,
                                                   is_nil_or_empty? { business["count_visits"] }.to_i) }
    end

    def Choosing_device_platform()
      label = @data["label"]
      date_building = @data["date_building"]
      business = @data["data"]
      execute { Chosens.new.Choosing_device_platform(label,
                                                     date_building,
                                                     is_nil_or_empty? { business["count_visits"] }.to_i) }
    end

    #--------------------------------------------------------------------------------------
    # VISIT
    #--------------------------------------------------------------------------------------
    def Building_visits()
      label = @data["label"]
      date_building = @data["date_building"]
      business = @data["data"]
      objective_file = Flow.new(TMP, "objective", label, date_building, 1, ".yml")
      objective_file.write(YAML::dump business)
      objective_file.close
      execute { Visits.new(label, date_building).Building_visits(is_nil_or_empty? { business["count_visits"] }.to_i,
                                                                 is_nil_or_empty? { business["visit_bounce_rate"] }.to_f,
                                                                 is_nil_or_empty? { business["page_views_per_visit"] }.to_f,
                                                                 is_nil_or_empty? { business["avg_time_on_site"] }.to_f,
                                                                 is_nil_or_empty? { business["min_durations"] }.to_i,
                                                                 is_nil_or_empty? { business["min_pages"] }.to_i) }
    end

    def Building_planification()
      label = @data["label"]
      date_building = @data["date_building"]
      objective = YAML::load Flow.new(TMP, "objective", label, date_building, 1, ".yml").read
      execute { Visits.new(label, date_building).Building_planification(is_nil_or_empty? { objective["hourly_distribution"] },
                                                                        is_nil_or_empty? { objective["count_visits"] }.to_i) }
    end

    def Extending_visits()
      label = @data["label"]
      date_building = @data["date_building"]
      objective_file = Flow.new(TMP, "objective", label, date_building, 1, ".yml")
      objective = YAML::load objective_file.read
      objective_file.close
      begin
        objective_file.delete
      rescue Exception => e
        @logger.an_event.warn e
      end
      execute { Visits.new(label, date_building).Extending_visits(is_nil_or_empty? { objective["count_visits"] }.to_i,
                                                                  objective["account_ga"],
                                                                  is_nil_or_empty? { objective["return_visitor_rate"] }.to_f) }
    end

    def Publishing_visits()
      label = @data["label"]
      date_building = @data["date_building"]
      business = @data["data"]

      execute { Visits.new(label, date_building).Publishing_visits_by_hour(Time._load(business["start_time"]).hour) }
    end

    #--------------------------------------------------------------------------------------
    # private
    #--------------------------------------------------------------------------------------

    private
    def execute (&block)
      begin
        yield
      rescue Exception => e
        @logger.an_event.debug e
        raise TasklistException, e
      end
    end

    private
    def is_nil_or_empty? ()
      @logger.an_event.debug yield
      raise TasklistArgumentException, "argument is undefine" if yield.nil?
      raise TasklistArgumentException, "argument is empty" if !yield.nil? and yield.is_a?(String) and yield.empty?
      yield
    end
  end
end
