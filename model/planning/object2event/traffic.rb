require_relative 'policy'

module Planning

  class Traffic < Policy
    TRAFFIC_SOURCE_BACKLINKS_DAY = 0 * IceCube::ONE_DAY # jour d'entegistrement de l'event
    TRAFFIC_SOURCE_BACKLINKS_HOUR = 0 * IceCube::ONE_HOUR # heure d'enregistrement
    TRAFFIC_SOURCE_BACKLINKS_MIN = 30 * IceCube::ONE_MINUTE # min d'enregistrement + 30mn
    SCRAPING_WEBSITE_DAY =  0 * IceCube::ONE_DAY # jour d'entegistrement de l'event
    SCRAPING_WEBSITE_HOUR =  0 * IceCube::ONE_HOUR # heure d'enregistrement
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


    end

    def to_event
      super

      #Si demande suppression de la policy alors absence de periodicity et de business_building_objectives
      if @count_weeks.nil? and @monday_start.nil?
        @events += [
            Event.new(@key, "Scraping_traffic_source_organic"),
            Event.new(@key, "Scraping_traffic_source_referral"),
            Event.new(@key, "Scraping_website"),
            Event.new(@key, "Evaluating_traffic_source_organic"),
            Event.new(@key, "Evaluating_traffic_source_referral"),
            Event.new(@key, "Building_device_platform"),
            Event.new(@key, "Building_hourly_daily_distribution"),
            Event.new(@key, "Building_behaviour"),
            Event.new(@key, "Building_objectives"),
            Event.new(@key, "Building_landing_pages_direct"),
            Event.new(@key, "Building_landing_pages_organic"),
            Event.new(@key, "Building_landing_pages_referral"),
            Event.new(@key, "Choosing_device_platform"),
            Event.new(@key, "Choosing_landing_pages"),
            Event.new(@key, "Building_visits"),
            Event.new(@key, "Building_planification"),
            Event.new(@key, "Extending_visits"),
            Event.new(@key, "Publishing_visits")

        ]


      else
        periodicity_scraping_website = IceCube::Schedule.new(registering_time + SCRAPING_WEBSITE_DAY + SCRAPING_WEBSITE_HOUR + SCRAPING_WEBSITE_MIN,
                                                             :end_time => registering_time + @count_weeks * IceCube::ONE_WEEK)
        periodicity_scraping_website.add_recurrence_rule IceCube::Rule.monthly.until(registering_time + @count_weeks * IceCube::ONE_WEEK)

        periodicity_traffic_source_organic = IceCube::Schedule.new(registering_time + TRAFFIC_SOURCE_KEYWORDS_DAY + TRAFFIC_SOURCE_KEYWORDS_HOUR + TRAFFIC_SOURCE_KEYWORDS_MIN,
                                                                   :end_time => registering_time + @count_weeks * IceCube::ONE_WEEK)
        periodicity_traffic_source_organic.add_recurrence_rule IceCube::Rule.monthly.until(registering_time + @count_weeks * IceCube::ONE_WEEK)

        periodicity_traffic_source_referral = IceCube::Schedule.new(registering_time + TRAFFIC_SOURCE_BACKLINKS_DAY + TRAFFIC_SOURCE_BACKLINKS_HOUR + TRAFFIC_SOURCE_BACKLINKS_MIN,
                                                                    :end_time => registering_time + @count_weeks * IceCube::ONE_WEEK)
        periodicity_traffic_source_referral.add_recurrence_rule IceCube::Rule.monthly.until(registering_time + @count_weeks * IceCube::ONE_WEEK)


        @events += [
            Event.new(@key,
                      "Scraping_traffic_source_organic",
                      {

                          "periodicity" => periodicity_traffic_source_organic.to_yaml,
                          "business" => {
                              "policy_type" => @policy_type,
                              "policy_id" => @policy_id,
                              "website_label" => @website_label,
                              "url_root" => @url_root,
                              "max_duration" => @max_duration_scraping, #en jours
                              "website_id" => @website_id
                          }
                      }),
            Event.new(@key,
                      "Scraping_traffic_source_referral",
                      {

                          "periodicity" => periodicity_traffic_source_referral.to_yaml,
                          "business" => {
                              "policy_type" => @policy_type,
                              "policy_id" => @policy_id,
                              "website_label" => @website_label,
                              "url_root" => @url_root,
                              "website_id" => @website_id
                          }
                      }),
            Event.new(@key,
                      "Scraping_website",
                      {

                          "periodicity" => periodicity_scraping_website.to_yaml,
                          "business" => {
                              "policy_type" => @policy_type,
                              "policy_id" => @policy_id,
                              "website_label" => @website_label,
                              "url_root" => @url_root,
                              "count_page" => @count_page,
                              "max_duration" => @max_duration_scraping, #en jours
                              "schemes" => @schemes,
                              "types" => @types,
                              "website_id" => @website_id
                          }
                      }),
            Event.new(@key,
                      "Building_device_platform",
                      {
                          "pre_tasks" => ["Scraping_device_platform_plugin", "Scraping_device_platform_resolution"],
                          # "periodicity" => IceCube::Schedule.new(@monday_start +
                          #                                            BUILDING_DEVICE_PLATFORM_DAY +
                          #                                            BUILDING_DEVICE_PLATFORM_HOUR,
                          #                                        :end_time => @monday_start +
                          #                                            BUILDING_DEVICE_PLATFORM_DAY +
                          #                                            BUILDING_DEVICE_PLATFORM_HOUR +
                          #                                            @count_weeks * IceCube::ONE_WEEK).to_yaml,
                           "business" => {
                              "website_label" => @website_label,
                              "website_id" => @website_id,
                              "policy_id" => @policy_id,
                              "policy_type" => @policy_type
                          }
                      }),

            Event.new(@key,
                      "Building_hourly_daily_distribution",
                      {
                          "pre_tasks" => ["Scraping_hourly_daily_distribution"],
                          # "periodicity" => IceCube::Schedule.new(@monday_start +
                          #                                            BUILDING_HOURLY_DISTRIBUTION_DAY +
                          #                                            BUILDING_HOURLY_DISTRIBUTION_HOUR,
                          #                                        :end_time => @monday_start +
                          #                                            BUILDING_HOURLY_DISTRIBUTION_DAY +
                          #                                            BUILDING_HOURLY_DISTRIBUTION_HOUR +
                          #                                            @count_weeks * IceCube::ONE_WEEK).to_yaml,
                          "business" => {
                              "website_label" => @website_label,
                              "website_id" => @website_id,
                              "policy_id" => @policy_id,
                              "policy_type" => @policy_type
                          }
                      }),

            Event.new(@key,
                      "Building_behaviour",
                      {
                          "pre_tasks" => ["Scraping_behaviour"],
                          # "periodicity" => IceCube::Schedule.new(@monday_start +
                          #                                            BUILDING_BEHAVIOUR_DAY +
                          #                                            BUILDING_BEHAVIOUR_HOUR,
                          #                                        :end_time => @monday_start +
                          #                                            BUILDING_BEHAVIOUR_DAY +
                          #                                            BUILDING_BEHAVIOUR_HOUR +
                          #                                            @count_weeks * IceCube::ONE_WEEK).to_yaml,
                          "business" => {
                              "website_label" => @website_label,
                              "website_id" => @website_id,
                              "policy_id" => @policy_id,
                              "policy_type" => @policy_type
                          }
                      }),

            Event.new(@key,
                      "Building_objectives",
                      {
                          "pre_tasks" => ["Building_hourly_daily_distribution", "Building_behaviour"],
                          # "periodicity" => IceCube::Schedule.new(@monday_start +
                          #                                            BUILDING_OBJECTIVES_DAY +
                          #                                            BUILDING_OBJECTIVES_HOUR,
                          #                                        :end_time => @monday_start +
                          #                                            BUILDING_OBJECTIVES_DAY +
                          #                                            BUILDING_OBJECTIVES_HOUR +
                          #                                            @count_weeks * IceCube::ONE_WEEK).to_yaml,
                          "business" => {
                              "change_count_visits_percent" => @change_count_visits_percent,
                              "change_bounce_visits_percent" => @change_bounce_visits_percent,
                              "direct_medium_percent" => @direct_medium_percent,
                              "organic_medium_percent" => @organic_medium_percent,
                              "referral_medium_percent" => @referral_medium_percent,
                              "advertising_percent" => @advertising_percent,
                              "advertisers" => @advertisers,
                              "website_label" => @website_label,
                              "monday_start" => @monday_start,
                              "count_weeks" => @count_weeks,
                              "website_id" => @website_id,
                              "policy_id" => @policy_id,
                              "url_root" => @url_root,
                              "min_count_page_advertiser" => @min_count_page_advertiser,
                              "max_count_page_advertiser" => @max_count_page_advertiser,
                              "min_duration_page_advertiser" => @min_duration_page_advertiser,
                              "max_duration_page_advertiser" => @max_duration_page_advertiser,
                              "percent_local_page_advertiser" => @percent_local_page_advertiser,
                              "duration_referral" => @duration_referral,
                              "min_count_page_organic" => @min_count_page_organic,
                              "max_count_page_organic" => @max_count_page_organic,
                              "min_duration_page_organic" => @min_duration_page_organic,
                              "max_duration_page_organic" => @max_duration_page_organic,
                              "min_duration" => @min_duration,
                              "max_duration" => @max_duration,
                              "min_duration_website" => @min_duration_website,
                              "min_pages_website" => @min_pages_website,
                              "policy_type" => @policy_type
                          }
                      }),

            Event.new(@key,
                      "Building_landing_pages_direct",
                      {
                          "pre_tasks" => ["Scraping_website"],

                          # "periodicity" => IceCube::Schedule.new(@registering_time +
                          #                                            BUILDING_LANDING_PAGES_DIRECT_DAY +
                          #                                            BUILDING_LANDING_PAGES_DIRECT_HOUR,
                          #                                        :end_time => @registering_time +
                          #                                            BUILDING_LANDING_PAGES_DIRECT_DAY +
                          #                                            BUILDING_LANDING_PAGES_DIRECT_HOUR +
                          #                                            @count_weeks * IceCube::ONE_WEEK).to_yaml,
                          "business" => {
                              "website_label" => @website_label,
                              "website_id" => @website_id,
                              "policy_id" => @policy_id,
                              "policy_type" => @policy_type
                          }
                      })
        ]
      end

      @events

    end
  end


end