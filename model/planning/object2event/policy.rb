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
         :website_label, #utilisé par SeaAttack(sea.label)
         :website_id, #utilisé par SeaAttack(sea.id)
         :policy_id, #utilisé par SeaAttack
         :policy_type, #utilisé par SeaAttack
         :count_weeks, #utilisé par SeaAttack
         :monday_start,
         :registering_date,
         :registering_time, # jour et heure d'enregistrement de la policy
         :duration_referral,
         :min_count_page_organic, #utilisé par SeaAttack
         :max_count_page_organic, #utilisé par SeaAttack
         :min_duration_page_organic, #utilisé par SeaAttack
         :max_duration_page_organic, #utilisé par SeaAttack
         :min_duration, #utilisé par SeaAttack
         :max_duration, #utilisé par SeaAttack
         :min_duration_website, #utilisé par SeaAttack
         :min_pages_website, #utilisé par SeaAttack
         :hourly_daily_distribution,
         :percent_new_visit,
         :visit_bounce_rate,
         :avg_time_on_site,
         :page_views_per_visit,
         :count_visits_per_day,
         :statistic_type, #utilisé par SeaAttack
         :key,
         :events,
         :building_behaviour, #utiliser pour passer l'event aux class Trafficn et Rank pour affecter la var pre_task
         :building_hourly_daily_distribution, #utiliser pour passer l'event aux class Trafficn et Rank pour affecter la var pre_task
         :execution_mode #utilisé par SeaAttack # mode d'execution de la policy : manuel (Piloté au moyen de statupweb) ou autom (piloté par Calendar)

    def initialize(data)
      @website_label = data[:website_label]
      @count_weeks = data[:count_weeks]
      @website_id = data[:website_id]
      @policy_id = data[:policy_id]


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
      @execution_mode = data[:execution_mode]
      case @statistics_type
        when "custom"
          @hourly_daily_distribution = data[:hourly_daily_distribution]
          @percent_new_visit = data[:percent_new_visit]
          @visit_bounce_rate = data[:visit_bounce_rate]
          @avg_time_on_site = data[:avg_time_on_site]
          @page_views_per_visit = data[:page_views_per_visit]
          @count_visits_per_day = data[:count_visits_per_day]
          @registering_date = Time.utc(Date.today.year, Date.today.month, Date.today.day, Time.now.hour, Time.now.min).localtime
        when "ga"
          @registering_date = $staging == "development" ?
              Time.utc(Date.today.year, Date.today.month, Date.today.day, Time.now.hour, Time.now.min).localtime
          :
              Time.utc(Date.today.year, Date.today.month, Date.today.day, 0, 0).localtime
        when "default"
          @registering_date = Time.utc(Date.today.year, Date.today.month, Date.today.day, Time.now.hour, Time.now.min).localtime
      end

      @events = []
    end

    def to_event(plan_date=@monday_start)


      periodicity_scraping_device_platform_plugin = IceCube::Schedule.new(plan_date +
                                                                              @scraping_device_platform_plugin_day * IceCube::ONE_DAY +
                                                                              @scraping_device_platform_plugin_hour * IceCube::ONE_HOUR +
                                                                              @scraping_device_platform_plugin_min * IceCube::ONE_MINUTE,
                                                                          :end_time => plan_date +
                                                                              @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)
      periodicity_scraping_device_platform_plugin.add_recurrence_rule IceCube::Rule.weekly.until(plan_date +
                                                                                                     @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)

      periodicity_scraping_hourly_distribution = IceCube::Schedule.new(plan_date +
                                                                           @scraping_hourly_distribution_day * IceCube::ONE_DAY +
                                                                           @scraping_hourly_distribution_hour * IceCube::ONE_HOUR +
                                                                           @scraping_hourly_distribution_min * IceCube::ONE_MINUTE,
                                                                       :end_time => plan_date +
                                                                           @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)
      periodicity_scraping_hourly_distribution.add_recurrence_rule IceCube::Rule.weekly.until(plan_date +
                                                                                                  @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)

      periodicity_scraping_behaviour = IceCube::Schedule.new(plan_date +
                                                                 @scraping_behaviour_day * IceCube::ONE_DAY +
                                                                 @scraping_behaviour_hour * IceCube::ONE_HOUR +
                                                                 @scraping_behaviour_min * IceCube::ONE_MINUTE,
                                                             :end_time => plan_date +
                                                                 @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)
      periodicity_scraping_behaviour.add_recurrence_rule IceCube::Rule.weekly.until(plan_date +
                                                                                        @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)


      periodicity_scraping_device_platform_resolution = IceCube::Schedule.new(plan_date +
                                                                                  @scraping_device_platform_resolution_day * IceCube::ONE_DAY +
                                                                                  @scraping_device_platform_resolution_hour * IceCube::ONE_HOUR +
                                                                                  @scraping_device_platform_resolution_min* IceCube::ONE_MINUTE,
                                                                              :end_time => plan_date +
                                                                                  @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)
      periodicity_scraping_device_platform_resolution.add_recurrence_rule IceCube::Rule.weekly.until(plan_date +
                                                                                                         @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)


      periodicity_building_device_platform = IceCube::Schedule.new(plan_date +
                                                                       @building_device_platform_day * IceCube::ONE_DAY +
                                                                       @building_device_platform_hour * IceCube::ONE_HOUR +
                                                                       @building_device_platform_min * IceCube::ONE_MINUTE,
                                                                   :end_time => plan_date +
                                                                       @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)

      periodicity_building_device_platform.add_recurrence_rule IceCube::Rule.weekly.until(plan_date +
                                                                                              @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)

      periodicity_building_hourly_distribution = IceCube::Schedule.new(plan_date +
                                                                           @building_hourly_distribution_day * IceCube::ONE_DAY +
                                                                           @building_hourly_distribution_hour * IceCube::ONE_HOUR +
                                                                           @building_hourly_distribution_min * IceCube::ONE_MINUTE,
                                                                       :end_time => plan_date +
                                                                           @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)

      periodicity_building_hourly_distribution.add_recurrence_rule IceCube::Rule.weekly.until(plan_date +
                                                                                                  @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)

      periodicity_building_behaviour = IceCube::Schedule.new(plan_date +
                                                                 @building_behaviour_day * IceCube::ONE_DAY +
                                                                 @building_behaviour_hour * IceCube::ONE_HOUR +
                                                                 @building_behaviour_min * IceCube::ONE_MINUTE,
                                                             :end_time => plan_date +
                                                                 @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)

      periodicity_building_behaviour.add_recurrence_rule IceCube::Rule.weekly.until(plan_date +
                                                                                        @count_weeks * IceCube::ONE_WEEK - IceCube::ONE_DAY)

      business.merge!({"profil_id_ga" => @profil_id_ga}) if @statistics_type == :ga

      @events += [

          scraping_device_platform_plugin = Event.new("Scraping_device_platform_plugin",
                                                      periodicity_scraping_device_platform_plugin,
                                                      @execution_mode,
                                                      {
                                                          :policy_type => @policy_type,
                                                          :policy_id => @policy_id,
                                                          :website_label => @website_label,
                                                          :website_id => @website_id,
                                                          :statistic_type => @statistics_type
                                                      }),
          scraping_device_platform_resolution = Event.new("Scraping_device_platform_resolution",
                                                          periodicity_scraping_device_platform_resolution,
                                                          @execution_mode,
                                                          {
                                                              :policy_type => @policy_type,
                                                              :policy_id => @policy_id,
                                                              :website_label => @website_label,
                                                              :website_id => @website_id,
                                                              :statistic_type => @statistics_type
                                                          }),
          scraping_hourly_daily_distribution = Event.new("Scraping_hourly_daily_distribution",
                                                         periodicity_scraping_hourly_distribution,
                                                         @execution_mode,
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
          scraping_behaviour = Event.new("Scraping_behaviour",
                                         periodicity_scraping_behaviour,
                                         @execution_mode,
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
                                                 :page_views_per_visit => @page_views_per_visit,
                                                 :count_visits_per_day => @count_visits_per_day
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
                    periodicity_building_device_platform,
                    @execution_mode,
                    {
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :policy_id => @policy_id,
                        :policy_type => @policy_type
                    },
                    [scraping_device_platform_plugin, scraping_device_platform_resolution]),

          @building_hourly_daily_distribution = Event.new("Building_hourly_daily_distribution",
                                                          periodicity_building_hourly_distribution,
                                                          @execution_mode,
                                                          {
                                                              :website_label => @website_label,
                                                              :website_id => @website_id,
                                                              :policy_id => @policy_id,
                                                              :policy_type => @policy_type
                                                          },
                                                          [scraping_hourly_daily_distribution]),
          @building_behaviour = Event.new("Building_behaviour",
                                          periodicity_building_behaviour,
                                          @execution_mode,
                                          {
                                              :website_label => @website_label,
                                              :website_id => @website_id,
                                              :policy_id => @policy_id,
                                              :policy_type => @policy_type
                                          },
                                          [scraping_behaviour])

      ]
    end

  end

end