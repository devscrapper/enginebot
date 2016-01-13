require_relative '../event'

module Planning

  class Policy

    attr :scraping_traffic_source_organic_day,
         :scraping_traffic_source_organic_hour,
         :scraping_traffic_source_organic_min,
         :scraping_device_platform_plugin_day,
         :scraping_device_platform_plugin_hour,
         :scraping_device_platform_plugin_min,
         :scraping_device_platform_resolution_day,
         :scraping_device_platform_resolution_hour,
         :scraping_device_platform_resolution_min,
         :scraping_hourly_distribution_day,
         :scraping_hourly_distribution_hour,
         :scraping_hourly_distribution_min,
         :scraping_behaviour_day,
         :scraping_behaviour_hour,
         :scraping_behaviour_min,
         :building_device_platform_day,
         :building_device_platform_hour,
         :building_device_platform_min,
         :building_hourly_distribution_day,
         :building_hourly_distribution_hour,
         :building_hourly_distribution_min,
         :building_behaviour_day,
         :building_behaviour_hour,
         :building_behaviour_min,
         :building_landing_pages_organic_day,
         :building_landing_pages_organic_hour,
         :building_landing_pages_organic_min,
         :website_label,
         :website_id,
         :policy_id,
         :policy_type,
         :count_weeks,
         :monday_start,
         :registering_time,
         :url_root,
         :min_count_page_advertiser,
         :max_count_page_advertiser,
         :min_duration_page_advertiser,
         :max_duration_page_advertiser,
         :percent_local_page_advertiser,
         :duration_referral,
         :min_count_page_organic,
         :max_count_page_organic,
         :min_duration_page_organic,
         :max_duration_page_organic,
         :min_duration,
         :max_duration,
         :min_duration_website,
         :min_pages_website,
         :hourly_daily_distribution,
         :percent_new_visit,
         :visit_bounce_rate,
         :avg_time_on_site,
         :page_views_per_visit,
         :statistic_type,
         :max_duration_scraping,
         :key,
         :events,
         :registering_time

    def initialize(data)
      @website_label = data[:website_label]
      d = Date.parse(data[:monday_start])
      @monday_start = Time.local(d.year, d.month, d.day) # iceCube a besoin d'un Time et pas d'un Date
      @registering_time = Time.local(Date.today.year, Date.today.month, Date.today.day, Time.now.hour, Time.now.min)
      @count_weeks = data[:count_weeks]
      @website_id = data[:website_id]
      @policy_id = data[:policy_id]
      @url_root = data[:url_root]
      @min_count_page_advertiser = data[:min_count_page_advertiser]
      @max_count_page_advertiser = data[:max_count_page_advertiser]
      @min_duration_page_advertiser = data[:min_duration_page_advertiser]
      @max_duration_page_advertiser = data[:max_duration_page_advertiser]
      @percent_local_page_advertiser = data[:percent_local_page_advertiser]
      @duration_referral = data[:duration_referral]
      @min_count_page_organic = data[:min_count_page_organic]
      @max_count_page_organic = data[:max_count_page_organic]
      @min_duration_page_organic = data[:min_duration_page_organic]
      @max_duration_page_organic = data[:max_duration_page_organic]
      @min_duration = data[:min_duration]
      @max_duration = data[:max_duration]
      @min_duration_website = data[:min_duration_website]
      @min_pages_website = data[:min_pages_website]
      @statistics_type = data[:statistics_type]
      @max_duration_scraping = data[:max_duration_scraping]
      if @statistics_type == "custom"
        @hourly_daily_distribution = data[:hourly_daily_distribution]
        @percent_new_visit = data[:percent_new_visit]
        @visit_bounce_rate = data[:visit_bounce_rate]
        @avg_time_on_site = data[:avg_time_on_site]
        @page_views_per_visit = data[:page_views_per_visit]
      end

      @events = []
      @registering_time = Time.local(Date.today.year, Date.today.month, Date.today.day, Time.now.hour, Time.now.min)

    end

    def to_event
      periodicity_scraping_traffic_source_organic = IceCube::Schedule.new(@registering_time + @scraping_traffic_source_organic_day * IceCube::ONE_DAY +
                                                                              @scraping_traffic_source_organic_hour * IceCube::ONE_HOUR +
                                                                              @scraping_traffic_source_organic_min * IceCube::ONE_MINUTE,
                                                                          :end_time => @registering_time +
                                                                              @count_weeks * IceCube::ONE_WEEK)
      periodicity_scraping_traffic_source_organic.add_recurrence_rule IceCube::Rule.monthly.until(@registering_time +
                                                                                                      @count_weeks * IceCube::ONE_WEEK)

      periodicity_scraping_device_platform_plugin = IceCube::Schedule.new(@monday_start +
                                                                              @scraping_device_platform_plugin_day * IceCube::ONE_DAY +
                                                                              @scraping_device_platform_plugin_hour * IceCube::ONE_HOUR +
                                                                              @scraping_device_platform_plugin_min * IceCube::ONE_MINUTE,
                                                                          :end_time => @monday_start +
                                                                              @count_weeks * IceCube::ONE_WEEK)
      periodicity_scraping_device_platform_plugin.add_recurrence_rule IceCube::Rule.weekly.until(@monday_start +
                                                                                                     @count_weeks * IceCube::ONE_WEEK)

      periodicity_scraping_hourly_distribution = IceCube::Schedule.new(@monday_start +
                                                                           @scraping_hourly_distribution_day * IceCube::ONE_DAY +
                                                                           @scraping_hourly_distribution_hour * IceCube::ONE_HOUR +
                                                                           @scraping_hourly_distribution_min * IceCube::ONE_MINUTE,
                                                                       :end_time => @monday_start +
                                                                           @count_weeks * IceCube::ONE_WEEK)
      periodicity_scraping_hourly_distribution.add_recurrence_rule IceCube::Rule.weekly.until(@monday_start +
                                                                                                  @count_weeks * IceCube::ONE_WEEK)

      periodicity_scraping_behaviour = IceCube::Schedule.new(@monday_start +
                                                                 @scraping_behaviour_day * IceCube::ONE_DAY +
                                                                 @scraping_behaviour_hour * IceCube::ONE_HOUR +
                                                                 @scraping_behaviour_min * IceCube::ONE_MINUTE,
                                                             :end_time => @monday_start +
                                                                 @count_weeks * IceCube::ONE_WEEK)
      periodicity_scraping_behaviour.add_recurrence_rule IceCube::Rule.weekly.until(@monday_start +
                                                                                        @count_weeks * IceCube::ONE_WEEK)


      periodicity_scraping_device_platform_resolution = IceCube::Schedule.new(@monday_start +
                                                                                  @scraping_device_platform_resolution_day * IceCube::ONE_DAY +
                                                                                  @scraping_device_platform_resolution_hour * IceCube::ONE_HOUR +
                                                                                  @scraping_device_platform_resolution_min* IceCube::ONE_MINUTE,
                                                                              :end_time => @monday_start +
                                                                                  @count_weeks * IceCube::ONE_WEEK)
      periodicity_scraping_device_platform_resolution.add_recurrence_rule IceCube::Rule.weekly.until(@monday_start +
                                                                                                         @count_weeks * IceCube::ONE_WEEK)



      business.merge!({"profil_id_ga" => @profil_id_ga}) if @statistics_type == :ga

      @events += [
          Event.new("Scraping_traffic_source_organic",
                    periodicity_scraping_traffic_source_organic,
                    {
                        :policy_type => @policy_type,
                        :policy_id => @policy_id,
                        :website_label => @website_label,
                        :url_root => @url_root,
                        :max_duration => @max_duration_scraping, #en jours
                        :website_id => @website_id
                    }),
          Event.new("Scraping_device_platform_plugin",
                    periodicity_scraping_device_platform_plugin,
                    {
                        :policy_type => @policy_type,
                        :policy_id => @policy_id,
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :statistic_type => @statistics_type
                    }),
          Event.new("Scraping_device_platform_resolution",
                    periodicity_scraping_device_platform_resolution,
                    {
                        :policy_type => @policy_type,
                        :policy_id => @policy_id,
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :statistic_type => @statistics_type
                    }),
          Event.new("Scraping_hourly_daily_distribution",
                    periodicity_scraping_hourly_distribution,
                    @statistics_type == "custom" ?
                        {

                            :policy_type => @policy_type,
                            :policy_id => @policy_id,
                            :website_label => @website_label,
                            :website_id => @website_id,
                            :statistic_type => @statistics_type,
                            :hourly_daily_distribution => @hourly_daily_distribution
                        }
                    :
                        {
                            :policy_type => @policy_type,
                            :policy_id => @policy_id,
                            :website_label => @website_label,
                            :website_id => @website_id,
                            :statistic_type => @statistics_type
                        }),
          Event.new("Scraping_behaviour",
                    periodicity_scraping_behaviour,
                    @statistics_type == "custom" ?
                        {

                            :policy_type => @policy_type,
                            :policy_id => @policy_id,
                            :website_label => @website_label,
                            :website_id => @website_id,
                            :statistic_type => @statistics_type,
                            :percent_new_visit => @percent_new_visit,
                            :visit_bounce_rate => @visit_bounce_rate,
                            :avg_time_on_site => @avg_time_on_site,
                            :page_views_per_visit => @page_views_per_visit
                        }
                    :
                        {
                            :policy_type => @policy_type,
                            :policy_id => @policy_id,
                            :website_label => @website_label,
                            :website_id => @website_id,
                            :statistic_type => @statistics_type
                        }),
          Event.new("Building_device_platform",
                    IceCube::Schedule.new(@monday_start +
                                              @building_device_platform_day * IceCube::ONE_DAY +
                                              @building_device_platform_hour * IceCube::ONE_HOUR +
                                              @building_device_platform_min * IceCube::ONE_MINUTE,
                                          :end_time => @monday_start +
                                              @building_device_platform_day * IceCube::ONE_DAY +
                                              @building_device_platform_hour * IceCube::ONE_HOUR +
                                              @building_device_platform_min * IceCube::ONE_MINUTE +
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
                                              @building_hourly_distribution_day * IceCube::ONE_DAY +
                                              @building_hourly_distribution_hour * IceCube::ONE_HOUR +
                                              @building_hourly_distribution_min * IceCube::ONE_MINUTE,
                                          :end_time => @monday_start +
                                              @building_hourly_distribution_day * IceCube::ONE_DAY +
                                              @building_hourly_distribution_hour * IceCube::ONE_HOUR +
                                              @building_hourly_distribution_min * IceCube::ONE_MINUTE +
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
                                              @building_behaviour_day * IceCube::ONE_DAY +
                                              @building_behaviour_hour * IceCube::ONE_HOUR +
                                              @building_behaviour_min * IceCube::ONE_MINUTE,
                                          :end_time => @monday_start +
                                              @building_behaviour_day * IceCube::ONE_DAY +
                                              @building_behaviour_hour * IceCube::ONE_HOUR +
                                              @building_behaviour_min * IceCube::ONE_MINUTE +
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
                                              @building_objectives_day * IceCube::ONE_DAY +
                                              @building_objectives_hour * IceCube::ONE_HOUR +
                                              @building_objectives_min * IceCube::ONE_MINUTE,
                                          :end_time => @monday_start +
                                              @building_objectives_day * IceCube::ONE_DAY +
                                              @building_objectives_hour * IceCube::ONE_HOUR +
                                              @building_objectives_min * IceCube::ONE_MINUTE +
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
                        :min_pages_website => @min_pages_website
                    },
                    ["Building_hourly_daily_distribution", "Building_behaviour"])

      ]
    end

  end

end