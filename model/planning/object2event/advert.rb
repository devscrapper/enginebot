require_relative 'policy'
require_relative '../../../lib/parameter'

module Planning

  class Advert < Policy

    attr :advertisers, #type d'advertisers => Adwords dans un premier temps
         :advertising_percent, # le pourcentage de visit pour lesquelles on click sur un advert(100 par defaut)
         :count_visits_per_day, #noombre de visit par jour
         :max_duration_scraping, # durée de scraping du website, en jour
         :min_count_page_advertiser, # nombre min de page consulter chez l'advertiser
         :min_duration_page_advertiser, # duree min de consultation d'une page chez l'advertiser
         :max_count_page_advertiser, # nombre max de page consulter chez l'advertiser
         :max_duration_page_advertiser, # duree max de consultation d'une page chez l'advertiser
         :percent_local_page_advertiser, # pourcentage de page consulter  chez l'advertiser avant de partir sur un site externe
         :count_page, # nombre de page a scraper du website
         :url_root, # du website
         :schemes, # du website
         :types # du website


    def initialize(data)
      super(data)
      # policy data
      @policy_type = "advert"
      d = Date.parse(data[:monday_start])
      # Time.local bug qd on soustrait 21 ou 22 heure en décalant le time zone d'une heure
      # remplacement de time.local par Time.utc().localtime
      @monday_start = Time.utc(d.year, d.month, d.day).localtime # iceCube a besoin d'un Time et pas d'un Date
      @count_visits_per_day = data[:count_visits_per_day]
      @registering_date = $staging == "development" ?
          Time.utc(Date.today.year, Date.today.month, Date.today.day, Time.now.hour, Time.now.min).localtime
      :
          Time.utc(Date.today.year, Date.today.month, Date.today.day, 0, 0).localtime


      # advertiser data
      @advertisers = data[:advertisers]
      @advertising_percent = data[:advertising_percent]
      @min_count_page_advertiser = data[:min_count_page_advertiser]
      @max_count_page_advertiser = data[:max_count_page_advertiser]
      @min_duration_page_advertiser = data[:min_duration_page_advertiser]
      @max_duration_page_advertiser = data[:max_duration_page_advertiser]
      @percent_local_page_advertiser = data[:percent_local_page_advertiser]

      # website data
      @url_root = data[:url_root]
      @schemes = data[:schemes]
      @types = data[:types]
      @count_page = data[:count_page]
      @max_duration_scraping = data[:max_duration_scraping]

      unless data[:monday_start].nil? # iceCube a besoin d'un Time et pas d'un Date
        delay = (@monday_start.to_date - @registering_date.to_date).to_i
        raise "#{delay} day(s) remaining before start policy, it is too short to prepare #{@policy_type} policy, #{@max_duration_scraping} day(s) are require !" if delay <= @max_duration_scraping
      end

      begin
        parameters = Parameter.new(__FILE__)
      rescue Exception => e
        raise "loading parameter traffic failed : #{e.message}"

      else
        @scraping_traffic_source_website_day = parameters.scraping_traffic_source_website_day
        @scraping_traffic_source_website_hour = parameters.scraping_traffic_source_website_hour
        @scraping_traffic_source_website_min = parameters.scraping_traffic_source_website_min
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
        @building_landing_pages_direct_day = parameters.building_landing_pages_direct_day
        @building_landing_pages_direct_hour = parameters.building_landing_pages_direct_hour
        @building_landing_pages_direct_min = parameters.building_landing_pages_direct_min
      end
    end

    def to_event
      super(@registering_date)

      periodicity_scraping_traffic_source_website = IceCube::Schedule.new(@registering_date +
                                                                              @scraping_traffic_source_website_day * IceCube::ONE_DAY +
                                                                              @scraping_traffic_source_website_hour * IceCube::ONE_HOUR +
                                                                              @scraping_traffic_source_website_min * IceCube::ONE_MINUTE,
                                                                          :end_time => @registering_date +
                                                                              @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)

      periodicity_scraping_traffic_source_website.add_recurrence_rule IceCube::Rule.monthly.until(@registering_date +
                                                                                                      @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)

      periodicity_building_pages_direct = IceCube::Schedule.new(@registering_date +
                                                                    @building_landing_pages_direct_day * IceCube::ONE_DAY +
                                                                    @building_landing_pages_direct_hour * IceCube::ONE_HOUR +
                                                                    @building_landing_pages_direct_min * IceCube::ONE_MINUTE,
                                                                :end_time => @registering_date +
                                                                    @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)

      periodicity_building_pages_direct.add_recurrence_rule IceCube::Rule.monthly.until(@registering_date +
                                                                                            @count_weeks * IceCube::ONE_WEEK)
      periodicity_building_objectives = IceCube::Schedule.new(@registering_date +
                                                                  @building_objectives_day * IceCube::ONE_DAY +
                                                                  @building_objectives_hour * IceCube::ONE_HOUR +
                                                                  @building_objectives_min * IceCube::ONE_MINUTE,
                                                              :end_time => @registering_date +
                                                                  @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)

      periodicity_building_objectives.add_recurrence_rule IceCube::Rule.weekly.count(@count_weeks)

      @events += [
          scraping_website = Event.new("Scraping_website",
                                       periodicity_scraping_traffic_source_website,
                                       @execution_mode,
                                       {
                                           :policy_type => @policy_type,
                                           :policy_id => @policy_id,
                                           :website_label => @website_label,
                                           :website_id => @website_id,
                                           :url_root => @url_root,
                                           :count_page => @count_page, #nombre total de page à scraper
                                           :max_duration => @max_duration_scraping, #en jours
                                           :schemes => @schemes,
                                           :types => @types
                                       }),
          Event.new("Building_landing_pages_direct",
                    periodicity_building_pages_direct,
                    @execution_mode,
                    {
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :policy_id => @policy_id,
                        :policy_type => @policy_type
                    },
                    [scraping_website]),
          Event.new("Building_objectives",
                    periodicity_building_objectives,
                    @execution_mode,
                    {
                        :website_id => @website_id,
                        :website_label => @website_label,
                        :policy_type => @policy_type,
                        :policy_id => @policy_id,
                        :monday_start => @monday_start,
                        :count_weeks => @count_weeks,
                        :url_root => @url_root,
                        :count_visits_per_day => @count_visits_per_day,
                        :advertising_percent => @advertising_percent,
                        :advertisers => @advertisers,
                        :min_count_page_advertiser => @min_count_page_advertiser,
                        :max_count_page_advertiser => @max_count_page_advertiser,
                        :min_duration_page_advertiser => @min_duration_page_advertiser,
                        :max_duration_page_advertiser => @max_duration_page_advertiser,
                        :percent_local_page_advertiser => @percent_local_page_advertiser,
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