require_relative 'policy'


module Planning

  class Traffic < Policy

    attr :traffic_source_referral,
         :change_count_visits_percent,
         :change_bounce_visits_percent,
         :direct_medium_percent,
         :organic_medium_percent,
         :referral_medium_percent,
         :advertising_percent,
         :advertisers,
         :count_page,
         :schemes,
         :types

    def initialize(data)
      super(data)
      @policy_type = "traffic"
      @change_count_visits_percent = data[:change_count_visits_percent]
      @change_bounce_visits_percent = data[:change_bounce_visits_percent]
      @direct_medium_percent=data[:direct_medium_percent]
      @organic_medium_percent=data[:organic_medium_percent]
      @referral_medium_percent= data[:referral_medium_percent]
      @advertising_percent= data[:advertising_percent]
      @advertisers = data[:advertisers]
      @count_page = data[:count_page]
      @schemes = data[:schemes]
      @types = data[:types]
      @url_root = data[:url_root]
      @policy_type = "traffic"
      @max_duration_scraping = data[:max_duration_scraping]
      unless data[:monday_start].nil? # iceCube a besoin d'un Time et pas d'un Date
        delay = (@monday_start.to_date - Time.now.to_date).to_i
        raise "#{delay} day(s) remaining before start policy, it is too short to prepare #{@policy_type} policy, #{@max_duration_scraping} day(s) are require !" if delay < @max_duration_scraping
      end
      # iceCube a besoin d'un Time et pas d'un Date

      begin
        parameters = Parameter.new(__FILE__)
      rescue Exception => e
        raise "loading parameter traffic failed : #{e.message}"

      else
        @scraping_traffic_source_organic_day = parameters.scraping_traffic_source_organic_day
        @scraping_traffic_source_organic_hour = parameters.scraping_traffic_source_organic_hour
        @scraping_traffic_source_organic_min = parameters.scraping_traffic_source_organic_min
        @scraping_traffic_source_referral_day = parameters.scraping_traffic_source_referral_day
        @scraping_traffic_source_referral_hour = parameters.scraping_traffic_source_referral_hour
        @scraping_traffic_source_referral_min = parameters.scraping_traffic_source_referral_min
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
        @building_landing_pages_organic_day = parameters.building_landing_pages_organic_day
        @building_landing_pages_organic_hour = parameters.building_landing_pages_organic_hour
        @building_landing_pages_organic_min = parameters.building_landing_pages_organic_min
        @building_objectives_day = parameters.building_objectives_day
        @building_objectives_hour = parameters.building_objectives_hour
        @building_objectives_min = parameters.building_objectives_min
        @building_landing_pages_direct_day = parameters.building_landing_pages_direct_day
        @building_landing_pages_direct_hour = parameters.building_landing_pages_direct_hour
        @building_landing_pages_direct_min = parameters.building_landing_pages_direct_min
        @building_landing_pages_referral_day = parameters.building_landing_pages_referral_day
        @building_landing_pages_referral_hour = parameters.building_landing_pages_referral_hour
        @building_landing_pages_referral_min = parameters.building_landing_pages_referral_min
     end

    end

    def to_event
      super

      periodicity_scraping_traffic_source_website = IceCube::Schedule.new(@registering_time +
                                                                              @scraping_traffic_source_website_day * IceCube::ONE_DAY +
                                                                              @scraping_traffic_source_website_hour * IceCube::ONE_HOUR +
                                                                              @scraping_traffic_source_website_min * IceCube::ONE_MINUTE,
                                                                          :end_time => @registering_time +
                                                                              @count_weeks * IceCube::ONE_WEEK)
      periodicity_scraping_traffic_source_website.add_recurrence_rule IceCube::Rule.monthly.until(@registering_time +
                                                                                                      @count_weeks * IceCube::ONE_WEEK)


      periodicity_scraping_traffic_source_referral = IceCube::Schedule.new(@registering_time +
                                                                               @traffic_source_referral_day * IceCube::ONE_DAY +
                                                                               @traffic_source_referral_hour * IceCube::ONE_HOUR +
                                                                               @traffic_source_referral_min * IceCube::ONE_MINUTE,
                                                                           :end_time => @registering_time +
                                                                               @count_weeks * IceCube::ONE_WEEK)
      periodicity_scraping_traffic_source_referral.add_recurrence_rule IceCube::Rule.monthly.until(@registering_time +
                                                                                                       @count_weeks * IceCube::ONE_WEEK)


      periodicity_building_landing_pages_referral = IceCube::Schedule.new(@monday_start +
                                                                              @building_landing_pages_referral_day * IceCube::ONE_DAY +
                                                                              @building_landing_pages_referral_hour * IceCube::ONE_HOUR +
                                                                              @building_landing_pages_referral_min * IceCube::ONE_MINUTE,
                                                                          :end_time => @monday_start +
                                                                              @building_landing_pages_referral_day * IceCube::ONE_DAY +
                                                                              @building_landing_pages_referral_hour * IceCube::ONE_HOUR +
                                                                              @building_landing_pages_referral_min * IceCube::ONE_MINUTE +
                                                                              @count_weeks * IceCube::ONE_WEEK)
      periodicity_building_landing_pages_referral.add_recurrence_rule IceCube::Rule.daily.until(@monday_start +
                                                                                                    @building_landing_pages_referral_day * IceCube::ONE_DAY +
                                                                                                    @building_landing_pages_referral_hour * IceCube::ONE_HOUR +
                                                                                                    @building_landing_pages_referral_min * IceCube::ONE_MINUTE +
                                                                                                    @count_weeks * IceCube::ONE_WEEK)
      @events += [

          Event.new("Scraping_traffic_source_referral",
                    periodicity_scraping_traffic_source_referral,
                    {
                        :policy_type => @policy_type,
                        :policy_id => @policy_id,
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :url_root => @url_root
                    }),
          Event.new("Scraping_website",
                    periodicity_scraping_traffic_source_website,
                    {
                        :policy_type => @policy_type,
                        :policy_id => @policy_id,
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :url_root => @url_root,
                        :count_page => @count_page,
                        :max_duration => @max_duration_scraping, #en jours
                        :schemes => @schemes,
                        :types => @types
                    }),
          Event.new("Building_landing_pages_direct",
                    IceCube::Schedule.new(@registering_time +
                                              @building_landing_pages_direct_day * IceCube::ONE_DAY +
                                              @building_landing_pages_direct_hour * IceCube::ONE_HOUR +
                                              @building_landing_pages_direct_min * IceCube::ONE_MINUTE,
                                          :end_time => @registering_time +
                                              @building_landing_pages_direct_day * IceCube::ONE_DAY +
                                              @building_landing_pages_direct_hour * IceCube::ONE_HOUR +
                                              @building_landing_pages_direct_min * IceCube::ONE_MINUTE +
                                              @count_weeks * IceCube::ONE_WEEK),
                    {
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :policy_id => @policy_id,
                        :policy_type => @policy_type
                    },
                    ["Scraping_website"]),

          Event.new("Building_landing_pages_referral",
                    periodicity_building_landing_pages_referral,
                    {
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :policy_id => @policy_id,
                        :policy_type => @policy_type
                    },
                    ["Evaluating_traffic_source_referral"])
      ]


      @events

    end
  end


end