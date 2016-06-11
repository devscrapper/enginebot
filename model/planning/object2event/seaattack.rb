require_relative 'policy'
require_relative '../../../lib/parameter'

module Planning

  class Seaattack < Policy


    attr :advertisers, #type d'advertisers => Adwords dans un premier temps
         :advertising_percent, # le pourcentage de visit pour lesquelles on click sur un advert(100 par defaut)
         :keywords, # mot cle associé au Sea (Adword)
         :label_advertisings, #liste de label de l'advert Adwords sur lequel il faut cliquer
         :min_count_page_advertiser, # nombre min de page consulter chez l'advertiser
         :min_duration_page_advertiser, # duree min de consultation d'une page chez l'advertiser
         :max_count_page_advertiser, # nombre max de page consulter chez l'advertiser
         :max_duration_page_advertiser, # duree max de consultation d'une page chez l'advertiser
         :percent_local_page_advertiser, # pourcentage de page consulter  chez l'advertiser avant de partir sur un site externe
         :start_date, #jour d'exécution des objectives
         :start_time # jour et heure d'exécution des objectives ; calcul des visits et debut de leur publication

    def initialize(data)
      super(data)
      @advertisers = data[:advertisers]
      @advertising_percent = 100 #toutes visits click sur un advert. aucun interer de generer des visit qui ne clique pas # car il existe déjà des visits qui utilisent les mot clés.
      @keywords = data[:keywords]
      @label_advertisings = data[:label_advertisings]
      @min_count_page_advertiser = data[:min_count_page_advertiser]
      @min_duration_page_advertiser = data[:min_duration_page_advertiser]
      @max_count_page_advertiser = data[:max_count_page_advertiser]
      @max_duration_page_advertiser = data[:max_duration_page_advertiser]
      @percent_local_page_advertiser = data[:percent_local_page_advertiser]
      @policy_type = "seaattack"
      @start_date = Date.parse(data[:start_date])
      @start_time = Time.local(@start_date.year, @start_date.month, @start_date.day, 0, 0) # tranforme start_time de DateTime en Time pour IceCube
      @registering_time = Time.now

      # si la date d'execution des objectives est celle du jour d'enregstrement de la policy alors on planifier lexécution au plus tot
      # sinon au jour planifé qui par exemple le lendemain
      # dans tous les cas la préparation de la policy est déclenché au plus tot : des la reception de l'enregistrment de la policy
      @start_time = @start_time <= @registering_time ? @registering_time : @start_time

      begin
        parameters = Parameter.new(__FILE__)
      rescue Exception => e
        raise "loading parameter traffic failed : #{e.message}"

      else
        @scraping_traffic_source_organic_day = parameters.scraping_traffic_source_organic_day
        @scraping_traffic_source_organic_hour = parameters.scraping_traffic_source_organic_hour
        @scraping_traffic_source_organic_min = parameters.scraping_traffic_source_organic_min
        @scraping_device_platform_plugin_day = parameters.scraping_device_platform_plugin_day
        @scraping_device_platform_plugin_hour =parameters.scraping_device_platform_plugin_hour
        @scraping_device_platform_plugin_min =parameters.scraping_device_platform_plugin_min
        @scraping_device_platform_resolution_day = parameters.scraping_device_platform_resolution_day
        @scraping_device_platform_resolution_hour =parameters.scraping_device_platform_resolution_hour
        @scraping_device_platform_resolution_min =parameters.scraping_device_platform_resolution_min
        @scraping_hourly_distribution_day = parameters.scraping_hourly_distribution_day
        @scraping_hourly_distribution_hour = parameters.scraping_hourly_distribution_hour
        @scraping_hourly_distribution_min = parameters.scraping_hourly_distribution_min
        @scraping_behaviour_day = parameters.scraping_behaviour_day
        @scraping_behaviour_hour = parameters.scraping_behaviour_hour
        @scraping_behaviour_min =parameters.scraping_behaviour_min
        @building_device_platform_day = parameters.building_device_platform_day
        @building_device_platform_hour = parameters.building_device_platform_hour
        @building_device_platform_min = parameters.building_device_platform_min
        @building_hourly_distribution_day = parameters.building_hourly_distribution_day
        @building_hourly_distribution_hour = parameters.building_hourly_distribution_hour
        @building_hourly_distribution_min = parameters.building_hourly_distribution_min
        @building_behaviour_day = parameters.building_behaviour_day
        @building_behaviour_hour = parameters.building_behaviour_hour
        @building_behaviour_min = parameters.building_behaviour_min
        @building_objectives_day = parameters.building_objectives_day
        @building_objectives_hour = parameters.building_objectives_hour
        @building_objectives_min = parameters.building_objectives_min
      end
    end

    def to_event
      super(@registering_time)
      periodicity_scraping_traffic_source_organic = IceCube::Schedule.new(@registering_time + @scraping_traffic_source_organic_day * IceCube::ONE_DAY +
                                                                              @scraping_traffic_source_organic_hour * IceCube::ONE_HOUR +
                                                                              @scraping_traffic_source_organic_min * IceCube::ONE_MINUTE,
                                                                          :end_time => @registering_time +
                                                                              @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)

      periodicity_scraping_traffic_source_organic.add_recurrence_rule IceCube::Rule.monthly.until(@registering_time +
                                                                                                      @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)

      periodicity_building_objectives = IceCube::Schedule.new(@registering_time +
                                                                  @building_objectives_day * IceCube::ONE_DAY +
                                                                  @building_objectives_hour * IceCube::ONE_HOUR +
                                                                  @building_objectives_min * IceCube::ONE_MINUTE,
                                                              :end_time => @registering_time +
                                                                  @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)

      periodicity_building_objectives.add_recurrence_rule IceCube::Rule.weekly.count(@count_weeks)
      @events += [
          Event.new("Scraping_traffic_source_organic",
                    periodicity_scraping_traffic_source_organic,
                    @execution_mode,
                    {
                        :policy_type => @policy_type,
                        :policy_id => @policy_id,
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :keywords => @keywords
                    }),
          Event.new("Building_objectives",
                    periodicity_building_objectives,
                    @execution_mode,
                    {
                        :website_id => @website_id,
                        :website_label => @website_label,
                        :policy_type => @policy_type,
                        :policy_id => @policy_id,
                        :monday_start => @start_time,
                        :count_weeks => @count_weeks,
                        :advertising_percent => @advertising_percent,
                        :label_advertisings => @label_advertisings,
                        :advertisers => @advertisers,
                        :min_count_page_advertiser => @min_count_page_advertiser,
                        :max_count_page_advertiser => @max_count_page_advertiser,
                        :min_duration_page_advertiser => @min_duration_page_advertiser,
                        :max_duration_page_advertiser => @max_duration_page_advertiser,
                        :percent_local_page_advertiser => @percent_local_page_advertiser,
                        :min_count_page_organic => @min_count_page_organic,
                        :max_count_page_organic => @max_count_page_organic,
                        :min_duration_page_organic => @min_duration_page_organic,
                        :max_duration_page_organic => @max_duration_page_organic,
                        :min_duration => @min_duration,
                        :max_duration => @max_duration,
                        :min_duration_website => @min_duration_website,
                        :min_pages_website => @min_pages_website
                    },
                    [@building_hourly_daily_distribution, @building_behaviour])
      ]
    end

  end


end