require_relative '../event'

module Planning

  class Objective
    attr :evaluating_traffic_source_organic_day,
         :evaluating_traffic_source_organic_hour,
         :evaluating_traffic_source_organic_min,
         :evaluating_traffic_source_referral_day,
         :evaluating_traffic_source_referral_hour,
         :evaluating_traffic_source_referral_min,
         :choosing_device_platform_day,
         :choosing_device_platform_hour,
         :choosing_device_platform_min,
         :choosing_landing_pages_day,
         :choosing_landing_pages_hour,
         :choosing_landing_pages_min,
         :building_visits_day,
         :building_visits_hour,
         :building_visits_min,
         :building_planification_day,
         :building_planification_hour,
         :building_planification_min,
         :extending_visits_day,
         :extending_visits_hour,
         :extending_visits_min,
         :start_publishing_visits_day,
         :start_publishing_visits_hour,
         :end_publishing_visits_day,
         :end_publishing_visits_hour,
         :count_visits,
         :website_label,
         :start_time,
         :visit_bounce_rate,
         :page_views_per_visit,
         :avg_time_on_site,
         :min_durations,
         :min_pages,
         :hourly_distribution,
         :direct_medium_percent,
         :organic_medium_percent,
         :referral_medium_percent,
         :url_root,
         :advertising_percent,
         :advertisers,
         :periodicity,
         :objective_id,
         :website_id,
         :policy_id,
         :policy_type,
         :count_weeks,
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
         :objective_date,
         :key,
         :events


    def initialize(data)
      @policy_id = data[:policy_id]
      @policy_type = data[:policy_type]
      @count_weeks = data[:count_weeks]
      @objective_id = data[:objective_id]
      @count_visits = data[:count_visits]
      @website_label = data[:website_label]
      @website_id = data[:website_id]
      @visit_bounce_rate = data[:visit_bounce_rate]
      @page_views_per_visit = data[:page_views_per_visit]
      @avg_time_on_site = data[:avg_time_on_site]
      @min_durations= data[:min_durations]
      @min_pages = data[:min_pages]
      @hourly_distribution = data[:hourly_distribution]
      @direct_medium_percent=data[:direct_medium_percent]
      @organic_medium_percent=data[:organic_medium_percent]
      @referral_medium_percent= data[:referral_medium_percent]
      @advertising_percent= data[:advertising_percent]
      @advertisers = data[:advertisers]
      @periodicity = data[:periodicity]
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
      @url_root = data[:url_root]
      @objective_date = IceCube::Schedule.from_yaml(@periodicity).start_time
      @events = []
      begin
        parameters = Parameter.new(__FILE__)
      rescue Exception => e
        raise "loading parameter traffic failed : #{e.message}"

      else
        @evaluating_traffic_source_organic_day = parameters.evaluating_traffic_source_organic_day
        @evaluating_traffic_source_organic_hour = parameters.evaluating_traffic_source_organic_hour
        @evaluating_traffic_source_organic_min = parameters.evaluating_traffic_source_organic_min
        @evaluating_traffic_source_referral_day = parameters.evaluating_traffic_source_referral_day
        @evaluating_traffic_source_referral_hour = parameters.evaluating_traffic_source_referral_hour
        @evaluating_traffic_source_referral_min = parameters.evaluating_traffic_source_referral_min
        @choosing_device_platform_day = parameters.choosing_device_platform_day
        @choosing_device_platform_hour = parameters.choosing_device_platform_hour
        @choosing_device_platform_min = parameters.choosing_device_platform_min
        @choosing_landing_pages_day = parameters.choosing_landing_pages_day
        @choosing_landing_pages_hour = parameters.choosing_landing_pages_hour
        @choosing_landing_pages_min = parameters.choosing_landing_pages_min
        @building_visits_day = parameters.building_visits_day
        @building_visits_hour = parameters.building_visits_hour
        @building_visits_min = parameters.building_visits_min
        @building_planification_day = parameters.building_planification_day
        @building_planification_hour = parameters.building_planification_hour
        @building_planification_min = parameters.building_planification_min
        @extending_visits_day = parameters.extending_visits_day
        @extending_visits_hour = parameters.extending_visits_hour
        @extending_visits_min = parameters.extending_visits_min
        @start_publishing_visits_day = parameters.start_publishing_visits_day
        @start_publishing_visits_hour = parameters.start_publishing_visits_hour
        @end_publishing_visits_day = parameters.end_publishing_visits_day
        @end_publishing_visits_hour = parameters.end_publishing_visits_hour
        @building_landing_pages_referral_day = parameters.building_landing_pages_referral_day
        @building_landing_pages_referral_hour = parameters.building_landing_pages_referral_hour
        @building_landing_pages_referral_min = parameters.building_landing_pages_referral_min
        @building_landing_pages_organic_day = parameters.building_landing_pages_organic_day
        @building_landing_pages_organic_hour = parameters.building_landing_pages_organic_hour
        @building_landing_pages_organic_min = parameters.building_landing_pages_organic_min
      end
    end

    def to_event
      if @organic_medium_percent > 0

        periodicity_organic = IceCube::Schedule.new(@objective_date +
                                                        @evaluating_traffic_source_organic_day * IceCube::ONE_DAY +
                                                        @evaluating_traffic_source_organic_hour * IceCube::ONE_HOUR +
                                                        @evaluating_traffic_source_organic_min * IceCube::ONE_MINUTE,
                                                    :end_time => @objective_date +
                                                        @evaluating_traffic_source_organic_day * IceCube::ONE_DAY +
                                                        @evaluating_traffic_source_organic_hour * IceCube::ONE_HOUR +
                                                        @evaluating_traffic_source_organic_min * IceCube::ONE_MINUTE)
        periodicity_organic.add_recurrence_rule IceCube::Rule.daily.until(@objective_date +
                                                                              @evaluating_traffic_source_organic_day * IceCube::ONE_DAY +
                                                                              @evaluating_traffic_source_organic_hour * IceCube::ONE_HOUR +
                                                                              @evaluating_traffic_source_organic_min * IceCube::ONE_MINUTE)

        @events << Event.new("Evaluating_traffic_source_organic",
                             periodicity_organic,
                             {
                                 :website_label => @website_label,
                                 :building_date => @objective_date.to_date,
                                 :objective_id => @objective_id,
                                 :policy_id => @policy_id,
                                 :policy_type => @policy_type,
                                 :website_id => @website_id,
                                 :count_max => ((@organic_medium_percent * @count_visits / 100) * 1.2).round(0), # ajout de 20% de mot clé pour eviter les manques
                                 :url_root => @url_root
                             })
        periodicity_building_landing_pages_organic =IceCube::Schedule.new(@objective_date +
                                                                              @building_landing_pages_organic_day * IceCube::ONE_DAY +
                                                                              @building_landing_pages_organic_hour * IceCube::ONE_HOUR +
                                                                              @building_landing_pages_organic_min * IceCube::ONE_MINUTE,
                                                                          :end_time => @objective_date +
                                                                              @building_landing_pages_organic_day * IceCube::ONE_DAY +
                                                                              @building_landing_pages_organic_hour * IceCube::ONE_HOUR +
                                                                              @building_landing_pages_organic_min * IceCube::ONE_MINUTE)

        periodicity_building_landing_pages_organic.add_recurrence_rule IceCube::Rule.daily.until(@objective_date +
                                                                                                     @building_landing_pages_organic_day * IceCube::ONE_DAY +
                                                                                                     @building_landing_pages_organic_hour * IceCube::ONE_HOUR +
                                                                                                     @building_landing_pages_organic_min * IceCube::ONE_MINUTE )
        @events << Event.new("Building_landing_pages_organic",
                            periodicity_building_landing_pages_organic,
                            {
                                :website_label => @website_label,
                                :building_date => @objective_date.to_date,
                                :objective_id => @objective_id,
                                :website_id => @website_id,
                                :policy_id => @policy_id,
                                :policy_type => @policy_type
                            },
                            ["Evaluating_traffic_source_organic"])
      end

      # permet de ne pas planifier un event sur evaluating referral pour la policy Rank et de maière generale de gagner du temps
      if @referral_medium_percent > 0

        periodicity_referral = IceCube::Schedule.new(@objective_date +
                                                         @evaluating_traffic_source_referral_day * IceCube::ONE_DAY +
                                                         @evaluating_traffic_source_referral_hour * IceCube::ONE_HOUR +
                                                         @evaluating_traffic_source_referral_min * IceCube::ONE_MINUTE,
                                                     :end_time => @objective_date +
                                                         @evaluating_traffic_source_referral_day * IceCube::ONE_DAY +
                                                         @evaluating_traffic_source_referral_hour * IceCube::ONE_HOUR +
                                                         @evaluating_traffic_source_referral_min * IceCube::ONE_MINUTE)

        periodicity_referral.add_recurrence_rule IceCube::Rule.daily.until(@objective_date +
                                                                               @evaluating_traffic_source_referral_day * IceCube::ONE_DAY +
                                                                               @evaluating_traffic_source_referral_hour * IceCube::ONE_HOUR +
                                                                               @evaluating_traffic_source_referral_min * IceCube::ONE_MINUTE)

        @events << Event.new("Evaluating_traffic_source_referral",
                             periodicity_referral,
                             {
                                 :website_label => @website_label,
                                 :building_date => @objective_date.to_date,
                                 :objective_id => @objective_id,
                                 :policy_id => @policy_id,
                                 :policy_type => @policy_type,
                                 :count_max => ((@referral_medium_percent * @count_visits / 100) * 1.2).round(0), # ajout de 20% de mot clé pour eviter les manques
                                 :url_root => @url_root
                             })

        periodicity_building_landing_pages_referral = IceCube::Schedule.new(@objective_date +
                                                                                @building_landing_pages_referral_day * IceCube::ONE_DAY +
                                                                                @building_landing_pages_referral_hour * IceCube::ONE_HOUR +
                                                                                @building_landing_pages_referral_min * IceCube::ONE_MINUTE,
                                                                            :end_time => @objective_date +
                                                                                @building_landing_pages_referral_day * IceCube::ONE_DAY +
                                                                                @building_landing_pages_referral_hour * IceCube::ONE_HOUR +
                                                                                @building_landing_pages_referral_min * IceCube::ONE_MINUTE)
        periodicity_building_landing_pages_referral.add_recurrence_rule IceCube::Rule.daily.until(@objective_date +
                                                                                                      @building_landing_pages_referral_day * IceCube::ONE_DAY +
                                                                                                      @building_landing_pages_referral_hour * IceCube::ONE_HOUR +
                                                                                                      @building_landing_pages_referral_min * IceCube::ONE_MINUTE)

        @events <<  Event.new("Building_landing_pages_referral",
                  periodicity_building_landing_pages_referral,
                  {
                      :website_label => @website_label,
                      :building_date => @objective_date.to_date,
                      :objective_id => @objective_id,
                      :website_id => @website_id,
                      :policy_id => @policy_id,
                      :policy_type => @policy_type
                  },
                  ["Evaluating_traffic_source_referral"])

      end
      periodicity = IceCube::Schedule.new(@objective_date +
                                              @choosing_landing_pages_day * IceCube::ONE_DAY +
                                              @choosing_landing_pages_hour * IceCube::ONE_HOUR +
                                              @choosing_landing_pages_min * IceCube::ONE_MINUTE,
                                          :end_time => @objective_date +
                                              @choosing_landing_pages_day * IceCube::ONE_DAY +
                                              @choosing_landing_pages_hour * IceCube::ONE_HOUR +
                                              @choosing_landing_pages_min * IceCube::ONE_MINUTE)
      
      periodicity.add_recurrence_rule IceCube::Rule.daily.until(@objective_date +
                                                                    @choosing_landing_pages_day * IceCube::ONE_DAY +
                                                                    @choosing_landing_pages_hour * IceCube::ONE_HOUR +
                                                                    @choosing_landing_pages_min * IceCube::ONE_MINUTE)

      pre_tasks = []
      pre_tasks << "Building_landing_pages_organic" if @organic_medium_percent > 0
      pre_tasks << "Building_landing_pages_referral" if @referral_medium_percent > 0
      @events << Event.new("Choosing_landing_pages",
                           periodicity,
                           {
                               :policy_id => @policy_id,
                               :building_date => @objective_date.to_date,
                               :policy_type => @policy_type,
                               :objective_id => @objective_id,
                               :website_label => @website_label,
                               :count_visits => @count_visits,
                               :direct_medium_percent => @direct_medium_percent,
                               :organic_medium_percent => @organic_medium_percent,
                               :referral_medium_percent => @referral_medium_percent

                           },
                           pre_tasks)

      periodicity = IceCube::Schedule.new(@objective_date +
                                              @building_visits_day * IceCube::ONE_DAY +
                                              @building_visits_hour * IceCube::ONE_HOUR +
                                              @building_visits_min * IceCube::ONE_MINUTE,
                                          :end_time => @objective_date +
                                              @building_visits_day * IceCube::ONE_DAY +
                                              @building_visits_hour * IceCube::ONE_HOUR +
                                              @building_visits_min * IceCube::ONE_MINUTE)

      periodicity.add_recurrence_rule IceCube::Rule.daily.until(@objective_date +
                                                                    @building_visits_day * IceCube::ONE_DAY +
                                                                    @building_visits_hour * IceCube::ONE_HOUR +
                                                                    @building_visits_min * IceCube::ONE_MINUTE)

      @events << Event.new("Building_visits",
                           periodicity,
                           {
                               :objective_id => @objective_id,
                               :website_label => @website_label,
                               :building_date => @objective_date.to_date,
                               :policy_type => @policy_type,
                               :website_id => @website_id,
                               :policy_id => @policy_id,
                               :count_visits => @count_visits,
                               :visit_bounce_rate => @visit_bounce_rate,
                               :page_views_per_visit => @page_views_per_visit,
                               :avg_time_on_site => @avg_time_on_site,
                               :min_durations => @min_durations,
                               :min_pages => @min_pages,
                           },
                           ["Choosing_landing_pages"])
      periodicity = IceCube::Schedule.new(@objective_date +
                                              @building_planification_day * IceCube::ONE_DAY +
                                              @building_planification_hour * IceCube::ONE_HOUR +
                                              @building_planification_min * IceCube::ONE_MINUTE,
                                          :end_time => @objective_date +
                                              @building_planification_day * IceCube::ONE_DAY +
                                              @building_planification_hour * IceCube::ONE_HOUR +
                                              @building_planification_min * IceCube::ONE_MINUTE)
      periodicity.add_recurrence_rule IceCube::Rule.daily.until(@objective_date +
                                                                    @building_planification_day * IceCube::ONE_DAY +
                                                                    @building_planification_hour * IceCube::ONE_HOUR +
                                                                    @building_planification_min * IceCube::ONE_MINUTE)

      @events << Event.new("Building_planification",
                           periodicity,
                           {
                               :objective_id => @objective_id,
                               :website_label => @website_label,
                               :building_date => @objective_date.to_date,
                               :policy_type => @policy_type,
                               :website_id => @website_id,
                               :policy_id => @policy_id,
                               :count_visits => @count_visits,
                               :hourly_distribution => @hourly_distribution
                           },
                           ["Building_visits"])
      periodicity = IceCube::Schedule.new(@objective_date +
                                              @extending_visits_day * IceCube::ONE_DAY +
                                              @extending_visits_hour * IceCube::ONE_HOUR +
                                              @extending_visits_min * IceCube::ONE_MINUTE,
                                          :end_time => @objective_date +
                                              @extending_visits_day * IceCube::ONE_DAY +
                                              @extending_visits_hour * IceCube::ONE_HOUR +
                                              @extending_visits_min * IceCube::ONE_MINUTE)
      periodicity.add_recurrence_rule IceCube::Rule.daily.until(@objective_date +
                                                                    @extending_visits_day * IceCube::ONE_DAY +
                                                                    @extending_visits_hour * IceCube::ONE_HOUR +
                                                                    @extending_visits_min * IceCube::ONE_MINUTE)

      @events << Event.new("Extending_visits",
                           periodicity,
                           {
                               :objective_id => @objective_id,
                               :website_label => @website_label,
                               :building_date => @objective_date.to_date,
                               :policy_type => @policy_type,
                               :website_id => @website_id,
                               :policy_id => @policy_id,
                               :count_visits => @count_visits,
                               :advertising_percent => @advertising_percent,
                               :advertisers => @advertisers
                           },
                           ["Building_planification",
                            "Choosing_device_platform"])


      periodicity = IceCube::Schedule.new(@objective_date +
                                              @choosing_device_platform_day * IceCube::ONE_DAY +
                                              @choosing_device_platform_hour * IceCube::ONE_HOUR +
                                              @choosing_device_platform_min * IceCube::ONE_MINUTE,
                                          :end_time => @objective_date +
                                              @choosing_device_platform_day * IceCube::ONE_DAY +
                                              @choosing_device_platform_hour * IceCube::ONE_HOUR +
                                              @choosing_device_platform_min * IceCube::ONE_MINUTE)
      periodicity.add_recurrence_rule IceCube::Rule.daily.until(@objective_date +
                                                                     @choosing_device_platform_day * IceCube::ONE_DAY +
                                                                     @choosing_device_platform_hour * IceCube::ONE_HOUR +
                                                                     @choosing_device_platform_min * IceCube::ONE_MINUTE)

      @events << Event.new("Choosing_device_platform",
                           periodicity,
                           {
                               :policy_id => @policy_id,
                               :building_date => @objective_date.to_date,
                               :policy_type => @policy_type,
                               :objective_id => @objective_id,
                               :website_label => @website_label,
                               :count_visits => @count_visits
                           })

      periodicity = IceCube::Schedule.new(@objective_date +
                                              @start_publishing_visits_day * IceCube::ONE_DAY +
                                              @start_publishing_visits_hour * IceCube::ONE_HOUR,
                                          :end_time => @objective_date +
                                              @start_publishing_visits_day * IceCube::ONE_DAY +
                                              @start_publishing_visits_hour * IceCube::ONE_HOUR)
      periodicity.add_recurrence_rule IceCube::Rule.hourly.until(@objective_date +
                                                                     @start_publishing_visits_day * IceCube::ONE_DAY +
                                                                     @start_publishing_visits_hour * IceCube::ONE_HOUR)
      @events << Event.new("Publishing_visits",
                           periodicity,
                           {
                               :objective_id => @objective_id,
                               :building_date => @objective_date.to_date,
                               :policy_id => @policy_id,
                               :policy_type => @policy_type,
                               :website_label => @website_label,
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
                               :max_duration => @max_duration
                           })


      @events
    end
  end
end