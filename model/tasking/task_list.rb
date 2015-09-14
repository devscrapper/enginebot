require_relative 'event2task/objectives'
require_relative 'event2task/chosens'
require_relative 'event2task/visits'
require_relative 'event2task/inputs'

require 'json'

module Tasking
  class Tasklist

    PROGRESS_BAR_SIZE = 180
    TMP = Pathname(File.dirname(__FILE__) + "/../../tmp").realpath
    EOFLINE ="\n"
    SEPARATOR2=";"
    attr :data, :logger

    def initialize(data)
      @data = data
      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
    end

    #--------------------------------------------------------------------------------------
    # INPUT
    #--------------------------------------------------------------------------------------
    def Building_landing_pages_direct
      website_label = @data["website_label"]
      date_building = @data["date_building"]
      website_id = @data["website_id"]
      policy_id = @data["policy_id"]
      policy_type = @data["policy_type"]

      execute(__method__, website_label, date_building, website_id, policy_id, policy_type) {
        Inputs.new(website_label, date_building, policy_type).Building_landing_pages(:direct)
      }
    end

    def Building_landing_pages_organic
      website_label = @data["website_label"]
      date_building = @data["date_building"]
      website_id = @data["website_id"]
      policy_id = @data["policy_id"]
      policy_type = @data["policy_type"]

      execute(__method__, website_label, date_building, website_id, policy_id, policy_type) {
        Inputs.new(website_label, date_building, policy_type).Building_landing_pages(:organic)
      }
    end

    def Building_landing_pages_referral
      website_label = @data["website_label"]
      date_building = @data["date_building"]
      website_id = @data["website_id"]
      policy_id = @data["policy_id"]
      policy_type = @data["policy_type"]

      execute(__method__, website_label, date_building, website_id, policy_id, policy_type) {
        Inputs.new(website_label, date_building, policy_type).Building_landing_pages(:referral)
      }
    end


    def Building_objectives
      website_label = @data["website_label"]
      date_building = @data["date_building"]
      website_id = @data["website_id"]
      policy_id = @data["policy_id"]
      policy_type = @data["policy_type"]

      execute(__method__, website_label, date_building, website_id, policy_id, policy_type) {
        case policy_type
          when "traffic"
            Objectives.new(website_label,
                           date_building,
                           policy_id,
                           website_id,
                           policy_type).Building_objectives_traffic(is_nil_or_empty? { @data["change_count_visits_percent"] }.to_i,
                                                                    is_nil_or_empty? { @data["change_bounce_visits_percent"] }.to_i,
                                                                    is_nil_or_empty? { @data["direct_medium_percent"] }.to_i,
                                                                    is_nil_or_empty? { @data["organic_medium_percent"] }.to_i,
                                                                    is_nil_or_empty? { @data["referral_medium_percent"] }.to_i,
                                                                    is_nil_or_empty? { @data["advertising_percent"] }.to_i,
                                                                    is_nil_or_empty? { @data["advertisers"] },
                                                                    is_nil_or_empty? { @data["url_root"] })
          when "rank"
            Objectives.new(website_label,
                           date_building,
                           policy_id,
                           website_id,
                           policy_type).Building_objectives_rank(is_nil_or_empty? { @data["count_visits_per_day"] }.to_i,
                                                                 is_nil_or_empty? { @data["url_root"] })
        end
      }


    end

    #--------------------------------------------------------------------------------------
    # CHOSEN
    #--------------------------------------------------------------------------------------
    def Choosing_landing_pages
      website_label = @data["website_label"]
      date_building = @data["date_building"]
      website_id = @data["website_id"]
      policy_id = @data["policy_id"]
      policy_type = @data["policy_type"]

      execute(__method__, website_label, date_building, website_id, policy_id, policy_type) {
        Chosens.new(website_label, date_building, policy_type).Choosing_landing_pages(is_nil_or_empty? { @data["direct_medium_percent"] }.to_i,
                                                                                      is_nil_or_empty? { @data["organic_medium_percent"] }.to_i,
                                                                                      is_nil_or_empty? { @data["referral_medium_percent"] }.to_i,
                                                                                      is_nil_or_empty? { @data["count_visits"] }.to_i) }
    end

    def Choosing_device_platform
      website_label = @data["website_label"]
      date_building = @data["date_building"]
      website_id = @data["website_id"]
      policy_id = @data["policy_id"]
      policy_type = @data["policy_type"]

      execute(__method__, website_label, date_building, website_id, policy_id, policy_type) {
        Chosens.new(website_label, date_building, policy_type).Choosing_device_platform(is_nil_or_empty? { @data["count_visits"] }.to_i) }
    end

    #--------------------------------------------------------------------------------------
    # VISIT
    #--------------------------------------------------------------------------------------
    def Building_visits
      website_label = @data["website_label"]
      date_building = @data["date_building"]
      website_id = @data["website_id"]
      policy_id = @data["policy_id"]
      policy_type = @data["policy_type"]

      execute(__method__, website_label, date_building, website_id, policy_id, policy_type) {
        objective_file = Flow.new(TMP, "objective", policy_type, website_label, date_building, 1, ".yml")
        objective_file.write(YAML::dump @data)
        objective_file.close

        Visits.new(website_label, date_building, policy_type, website_id, policy_id).Building_visits(is_nil_or_empty? { @data["count_visits"] }.to_i,
                                                                                             is_nil_or_empty? { @data["visit_bounce_rate"] }.to_f,
                                                                                             is_nil_or_empty? { @data["page_views_per_visit"] }.to_f,
                                                                                             is_nil_or_empty? { @data["avg_time_on_site"] }.to_f,
                                                                                             is_nil_or_empty? { @data["min_durations"] }.to_i,
                                                                                             is_nil_or_empty? { @data["min_pages"] }.to_i) }
    end

    def Building_planification
      website_label = @data["website_label"]
      date_building = @data["date_building"]
      website_id = @data["website_id"]
      policy_id = @data["policy_id"]
      policy_type = @data["policy_type"]

      execute(__method__, website_label, date_building, website_id, policy_id, policy_type) {
        objective = YAML::load Flow.new(TMP, "objective", policy_type, website_label, date_building, 1, ".yml").read

        Visits.new(website_label, date_building, policy_type, website_id, policy_id).Building_planification(is_nil_or_empty? { objective["hourly_distribution"] },
                                                                                                    is_nil_or_empty? { objective["count_visits"] }.to_i) }
    end

    def Extending_visits
      website_label = @data["website_label"]
      date_building = @data["date_building"]
      website_id = @data["website_id"]
      policy_id = @data["policy_id"]
      policy_type = @data["policy_type"]

      execute(__method__, website_label, date_building, website_id, policy_id, policy_type) {
        objective_file = Flow.new(TMP, "objective", policy_type, website_label, date_building, 1, ".yml")
        objective = YAML::load objective_file.read
        objective_file.close
        begin
          objective_file.delete
        rescue Exception => e
          @logger.an_event.warn e
        end
        Visits.new(website_label, date_building, policy_type, website_id, policy_id).Extending_visits(is_nil_or_empty? { objective["count_visits"] }.to_i,
                                                                                              is_nil_or_empty? { objective["advertising_percent"].to_i },
                                                                                              is_nil_or_empty? { objective["advertisers"] }) }
    end

    def Reporting_visits
      website_label = @data["website_label"]
      date_building = @data["date_building"]
      website_id = @data["website_id"]
      policy_id = @data["policy_id"]
      policy_type = @data["policy_type"]

      execute(__method__, website_label, date_building, website_id, policy_id, policy_type) {
        Visits.new(website_label, date_building, policy_type, website_id, policy_id).Reporting_visits }
    end

    def Publishing_visits
      website_label = @data["website_label"]
      date_building = @data["date_building"]
      website_id = @data["website_id"]
      policy_id = @data["policy_id"]
      policy_type = @data["policy_type"]

      execute(__method__, website_label, date_building, website_id, policy_id, policy_type) {
        Visits.new(website_label, date_building, policy_type, website_id, policy_id).Publishing_visits_by_hour
      }
    end

    #--------------------------------------------------------------------------------------
    # private
    #--------------------------------------------------------------------------------------

    private
    def execute(task, website_label, date, website_id, policy_id, policy_type, objective_id = nil, &block)
      info = ["policy_type : #{policy_type}",
              " policy_id : #{policy_id}",
              " website_label : #{website_label}",
              " website_id : #{website_id}",
              " date : #{date}"]
      info << " objective_id : #{objective_id}" unless objective_id.nil?

      @logger.an_event.info "task <#{task}> for <#{info.join(",")}> is starting"
      begin

        yield(website_label, date)

      rescue Exception => e
        @logger.an_event.error "task <#{task}> for <#{info.join(",")}> is over => #{e.message}"

          #TODO preparer la valeur KO � envoyer � statupweb
      else
        @logger.an_event.info "task <#{task}> for <#{info.join(",")}> is over"
          #TODO preparer la valeur OK � envoyer � statupweb
      ensure

        #TODO revisiter la solution decoute du statupweb pour quelle ne soit pas d�di�e � compte rendu de traitement google_analytics.rb
        #TODO envoyer � statupweb le resultat de l'ex�cution de la tache comme cela est fait dans google_analytics.rb
        #TODO supprimer dans google analytics l'envoie vers statupweb
        #TODO supprimer dans statistics l'envoie vers statupweb
      end
    end

    private
    def is_nil_or_empty?
      @logger.an_event.debug yield
      raise StandardError, "argument is undefine" if yield.nil?
      raise StandardError, "argument is empty" if !yield.nil? and yield.is_a?(String) and yield.empty?
      yield
    end
  end
end
