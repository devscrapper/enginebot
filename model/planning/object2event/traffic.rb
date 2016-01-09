require_relative 'policy'

#TODO corriger les horaire planification puor ne pas commencer à hh:^00 pour eviter les conflit avec les publishon horaire
# TODO 2 taches commencent minuuit le samedi => décaler
module Planning

  class Traffic < Policy
    TRAFFIC_SOURCE_BACKLINKS_DAY = 0 * IceCube::ONE_DAY # jour d'entegistrement de l'event
    TRAFFIC_SOURCE_BACKLINKS_HOUR = 0 * IceCube::ONE_HOUR # heure d'enregistrement
    TRAFFIC_SOURCE_BACKLINKS_MIN = 30 * IceCube::ONE_MINUTE # min d'enregistrement + 30mn
    SCRAPING_WEBSITE_DAY = 0 * IceCube::ONE_DAY # jour d'entegistrement de l'event
    SCRAPING_WEBSITE_HOUR = 0 * IceCube::ONE_HOUR # heure d'enregistrement
    SCRAPING_WEBSITE_MIN = 45 * IceCube::ONE_MINUTE # min d'enregistrement + 30mn
    BUILDING_DEVICE_PLATFORM_DAY = -2 * IceCube::ONE_DAY #on decale d'un  jour j-2 =>Saturday
    BUILDING_DEVICE_PLATFORM_HOUR = 0 * IceCube::ONE_HOUR #heure de démarrage est 0h du matin
    BUILDING_HOURLY_DISTRIBUTION_DAY = -2 * IceCube::ONE_DAY
    BUILDING_HOURLY_DISTRIBUTION_HOUR = 0 * IceCube::ONE_HOUR
    BUILDING_BEHAVIOUR_DAY = -2 * IceCube::ONE_DAY
    BUILDING_BEHAVIOUR_HOUR = 0 * IceCube::ONE_HOUR
    BUILDING_OBJECTIVES_DAY = -2 * IceCube::ONE_DAY
    BUILDING_OBJECTIVES_HOUR = 0 * IceCube::ONE_HOUR
    BUILDING_LANDING_PAGES_DIRECT_DAY = 0* IceCube::ONE_DAY
    BUILDING_LANDING_PAGES_DIRECT_HOUR = 0 * IceCube::ONE_HOUR
    BUILDING_LANDING_PAGES_REFERRAL_DAY = -1 * IceCube::ONE_DAY
    BUILDING_LANDING_PAGES_REFERRAL_HOUR = 0 * IceCube::ONE_HOUR
    BUILDING_LANDING_PAGES_ORGANIC_DAY = -1 * IceCube::ONE_DAY
    BUILDING_LANDING_PAGES_ORGANIC_HOUR = 0 * IceCube::ONE_HOUR
    @@traffic_source_keywords_day
    @@traffic_source_keywords_hour
    @@traffic_source_keywords_min
    @@traffic_source_backlinks_day
    @@traffic_source_backlinks_hour
    @@traffic_source_backlinks_min
    @@traffic_source_website_day
    @@traffic_source_website_hour
    @@traffic_source_website_min
    @@building_device_platform_day
    @@building_device_platform_hour
    @@building_device_platform_min
    @@building_hourly_distribution_day
    @@building_hourly_distribution_hour
    @@building_hourly_distribution_min
    @@building_behaviour_day
    @@building_behaviour_hour
    @@building_behaviour_min
    @@building_objectives_day
    @@building_objectives_hour
    @@building_objectives_min
    @@building_landing_pages_direct_day
    @@building_landing_pages_direct_hour
    @@building_landing_pages_direct_min
    @@building_landing_pages_referral_day
    @@building_landing_pages_referral_hour
    @@building_landing_pages_referral_min
    @@building_landing_pages_organic_day
    @@building_landing_pages_organic_hour
    @@building_landing_pages_organic_min

    attr :change_count_visits_percent,
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
        @@traffic_source_keywords_day= 0
       @@traffic_source_keywords_hour= 0
       @@traffic_source_keywords_min= 0
       @@traffic_source_backlinks_day= 0
       @@traffic_source_backlinks_hour= 0
       @@traffic_source_backlinks_min= 30
       @@traffic_source_website_day= 0
       @@traffic_source_website_hour= 0
       @@traffic_source_website_min= 45
       @@building_device_platform_day= -2
       @@building_device_platform_hour= 0
       @@building_device_platform_min= 0
       @@building_hourly_distribution_day= -2
       @@building_hourly_distribution_hour= 0
       @@building_hourly_distribution_min= 0
       @@building_behaviour_day= -2
       @@building_behaviour_hour= 0
       @@building_behaviour_min= 0
       @@building_objectives_day= -2
       @@building_objectives_hour= 0
       @@building_objectives_min= 0
       @@building_landing_pages_direct_day= 0
       @@building_landing_pages_direct_hour= 0
       @@building_landing_pages_direct_min= 0
       @@building_landing_pages_referral_day= -1
       @@building_landing_pages_referral_hour= 0
       @@building_landing_pages_referral_min= 0
       @@building_landing_pages_organic_day= -1
       @@building_landing_pages_organic_hour= 0
       @@building_landing_pages_organic_min= 0
       end

    end

    def to_event
      super

      periodicity_scraping_website = IceCube::Schedule.new(@registering_time + SCRAPING_WEBSITE_DAY + SCRAPING_WEBSITE_HOUR + SCRAPING_WEBSITE_MIN,
                                                           :end_time => @registering_time + @count_weeks * IceCube::ONE_WEEK)
      periodicity_scraping_website.add_recurrence_rule IceCube::Rule.monthly.until(@registering_time + @count_weeks * IceCube::ONE_WEEK)

      periodicity_traffic_source_organic = IceCube::Schedule.new(@registering_time + TRAFFIC_SOURCE_KEYWORDS_DAY + TRAFFIC_SOURCE_KEYWORDS_HOUR + TRAFFIC_SOURCE_KEYWORDS_MIN,
                                                                 :end_time => @registering_time + @count_weeks * IceCube::ONE_WEEK)
      periodicity_traffic_source_organic.add_recurrence_rule IceCube::Rule.monthly.until(@registering_time + @count_weeks * IceCube::ONE_WEEK)

      periodicity_traffic_source_referral = IceCube::Schedule.new(@registering_time + TRAFFIC_SOURCE_BACKLINKS_DAY + TRAFFIC_SOURCE_BACKLINKS_HOUR + TRAFFIC_SOURCE_BACKLINKS_MIN,
                                                                  :end_time => @registering_time + @count_weeks * IceCube::ONE_WEEK)
      periodicity_traffic_source_referral.add_recurrence_rule IceCube::Rule.monthly.until(@registering_time + @count_weeks * IceCube::ONE_WEEK)


      periodicity_building_organic =IceCube::Schedule.new(@monday_start +
                                                              BUILDING_LANDING_PAGES_ORGANIC_DAY +
                                                              BUILDING_LANDING_PAGES_ORGANIC_HOUR,
                                                          :end_time => @monday_start +
                                                              BUILDING_LANDING_PAGES_ORGANIC_DAY +
                                                              BUILDING_LANDING_PAGES_ORGANIC_HOUR +
                                                              @count_weeks * IceCube::ONE_WEEK)

      periodicity_building_organic.add_recurrence_rule IceCube::Rule.daily.until(@monday_start +
                                                                                     BUILDING_LANDING_PAGES_ORGANIC_DAY +
                                                                                     BUILDING_LANDING_PAGES_ORGANIC_HOUR +
                                                                                     @count_weeks * IceCube::ONE_WEEK)

      periodicity_building_referral = IceCube::Schedule.new(@monday_start +
                                                                BUILDING_LANDING_PAGES_REFERRAL_DAY +
                                                                BUILDING_LANDING_PAGES_REFERRAL_HOUR,
                                                            :end_time => @monday_start +
                                                                BUILDING_LANDING_PAGES_REFERRAL_DAY +
                                                                BUILDING_LANDING_PAGES_REFERRAL_HOUR +
                                                                @count_weeks * IceCube::ONE_WEEK)
      periodicity_building_referral.add_recurrence_rule IceCube::Rule.daily.until(@monday_start +
                                                                                      BUILDING_LANDING_PAGES_REFERRAL_DAY +
                                                                                      BUILDING_LANDING_PAGES_REFERRAL_HOUR +
                                                                                      @count_weeks * IceCube::ONE_WEEK)
      @events += [
          Event.new("Scraping_traffic_source_organic",
                    periodicity_traffic_source_organic,
                    {
                        :policy_type => @policy_type,
                        :policy_id => @policy_id,
                        :website_label => @website_label,
                        :url_root => @url_root,
                        :max_duration => @max_duration_scraping, #en jours
                        :website_id => @website_id
                    }),
          Event.new("Scraping_traffic_source_referral",
                    periodicity_traffic_source_referral,
                    {
                        :policy_type => @policy_type,
                        :policy_id => @policy_id,
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :url_root => @url_root
                    }),
          Event.new("Scraping_website",
                    periodicity_scraping_website,
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
          Event.new("Building_device_platform",
                    IceCube::Schedule.new(@monday_start +
                                              BUILDING_DEVICE_PLATFORM_DAY +
                                              BUILDING_DEVICE_PLATFORM_HOUR,
                                          :end_time => @monday_start +
                                              BUILDING_DEVICE_PLATFORM_DAY +
                                              BUILDING_DEVICE_PLATFORM_HOUR +
                                              @count_weeks * IceCube::ONE_WEEK),
                    {
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :policy_id => @policy_id,
                        :policy_type => @policy_type
                    },
                    ["Scraping_device_platform_plugin", "Scraping_device_platform_resolution"]),
          Event.new("Building_hourly_daily_distribution",
                    IceCube::Schedule.new(@monday_start +
                                              BUILDING_HOURLY_DISTRIBUTION_DAY +
                                              BUILDING_HOURLY_DISTRIBUTION_HOUR,
                                          :end_time => @monday_start +
                                              BUILDING_HOURLY_DISTRIBUTION_DAY +
                                              BUILDING_HOURLY_DISTRIBUTION_HOUR +
                                              @count_weeks * IceCube::ONE_WEEK),
                    {
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :policy_id => @policy_id,
                        :policy_type => @policy_type
                    },
                    ["Scraping_hourly_daily_distribution"]),
          Event.new("Building_behaviour",
                    IceCube::Schedule.new(@monday_start +
                                              BUILDING_BEHAVIOUR_DAY +
                                              BUILDING_BEHAVIOUR_HOUR,
                                          :end_time => @monday_start +
                                              BUILDING_BEHAVIOUR_DAY +
                                              BUILDING_BEHAVIOUR_HOUR +
                                              @count_weeks * IceCube::ONE_WEEK),
                    {
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :policy_id => @policy_id,
                        :policy_type => @policy_type
                    },
                    ["Scraping_behaviour"]),
          Event.new("Building_objectives",
                    IceCube::Schedule.new(@monday_start +
                                              BUILDING_OBJECTIVES_DAY +
                                              BUILDING_OBJECTIVES_HOUR,
                                          :end_time => @monday_start +
                                              BUILDING_OBJECTIVES_DAY +
                                              BUILDING_OBJECTIVES_HOUR +
                                              @count_weeks * IceCube::ONE_WEEK),
                    {
                        :website_id => @website_id,
                        :website_label => @website_label,
                        :policy_type => @policy_type,
                        :policy_id => @policy_id,
                        :change_count_visits_percent => @change_count_visits_percent,
                        :change_bounce_visits_percent => @change_bounce_visits_percent,
                        :direct_medium_percent => @direct_medium_percent,
                        :organic_medium_percent => @organic_medium_percent,
                        :referral_medium_percent => @referral_medium_percent,
                        :advertising_percent => @advertising_percent,
                        :advertisers => @advertisers,
                        :monday_start => @monday_start,
                        :count_weeks => @count_weeks,
                        :url_root => @url_root,
                        :min_count_page_advertiser => @min_count_page_advertiser,
                        :max_count_page_advertiser => @max_count_page_advertiser,
                        :min_duration_page_advertiser => @min_duration_page_advertiser,
                        :max_duration_page_advertiser => @max_duration_page_advertiser,
                        :percent_local_page_advertiser => @percent_local_page_advertiser,
                        :duration_referral => @duration_referral,
                        :min_count_page_organic => @min_count_page_organic,
                        :max_count_page_organic => @max_count_page_organic,
                        :min_duration_page_organic => @min_duration_page_organic,
                        :max_duration_page_organic => @max_duration_page_organic,
                        :min_duration => @min_duration,
                        :max_duration => @max_duration,
                        :min_duration_website => @min_duration_website,
                        :min_pages_website => @min_pages_website,

                    },
                    ["Building_hourly_daily_distribution", "Building_behaviour"]),
          Event.new("Building_landing_pages_direct",
                    IceCube::Schedule.new(@registering_time +
                                              BUILDING_LANDING_PAGES_DIRECT_DAY +
                                              BUILDING_LANDING_PAGES_DIRECT_HOUR,
                                          :end_time => @registering_time +
                                              BUILDING_LANDING_PAGES_DIRECT_DAY +
                                              BUILDING_LANDING_PAGES_DIRECT_HOUR +
                                              @count_weeks * IceCube::ONE_WEEK),
                    {
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :policy_id => @policy_id,
                        :policy_type => @policy_type
                    },
                    ["Scraping_website"]),

          Event.new("Building_landing_pages_organic",
                    periodicity_building_organic,
                    {
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :policy_id => @policy_id,
                        :policy_type => @policy_type
                    },
                    ["Evaluating_traffic_source_organic"]),

          Event.new("Building_landing_pages_referral",
                    periodicity_building_referral,
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