require_relative '../event'

module Planning

  class Policy
    BUILDING_OBJECTIVES_DAY = -3 * IceCube::ONE_DAY #on decale d'un  jour j-3
    BUILDING_OBJECTIVES_HOUR = 12 * IceCube::ONE_HOUR #heure de démarrage est 12h du matin
    BUILDING_MATRIX_AND_PAGES_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
    BUILDING_MATRIX_AND_PAGES_HOUR = 0 * IceCube::ONE_HOUR #heure de démarrage est 0h du matin

    TRAFFIC_SOURCE_KEYWORDS_DAY = 0 * IceCube::ONE_DAY # jour d'entegistrement de l'event
    TRAFFIC_SOURCE_KEYWORDS_HOUR = 0 * IceCube::ONE_HOUR # heure d'enregistrement
    TRAFFIC_SOURCE_KEYWORDS_MIN = 15 * IceCube::ONE_MINUTE # min d'enregistrement + 15mn

    HOURLY_DAILY_DISTRIBUTION_DAY = -2 * IceCube::ONE_DAY #on decale d'un  jour j-1
    HOURLY_DAILY_DISTRIBUTION_HOUR = 2 * IceCube::ONE_HOUR #heure de démarrage est minuit
    HOURLY_DAILY_DISTRIBUTION_MIN = 30 * IceCube::ONE_MINUTE #min denregistrement + 30mn
    BEHAVIOUR_DAY = -2 * IceCube::ONE_DAY #on decale d'un  jour j-1
    BEHAVIOUR_HOUR = 3 * IceCube::ONE_HOUR #heure de démarrage est 1h du matin
    DEVICE_PLATFORM_PLUGIN_DAY = -2 * IceCube::ONE_DAY #on decale d'un  jour j-1
    DEVICE_PLATFORM_PLUGIN_HOUR = 1 * IceCube::ONE_HOUR #heure de démarrage est minuit
    DEVICE_PLATFORM_PLUGIN_MIN = 30 * IceCube::ONE_MINUTE #min denregistrement + 30mn
    DEVICE_PLATFORM_RESOLUTION_DAY = -2 * IceCube::ONE_DAY #on decale d'un  jour j-1
    DEVICE_PLATFORM_RESOLUTION_HOUR = 2 * IceCube::ONE_HOUR #heure de démarrage est 1h du matin

    attr :website_label,
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
      if @statistics_type == :custom
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


      periodicity_hourly_daily_distribution = IceCube::Schedule.new(@monday_start + HOURLY_DAILY_DISTRIBUTION_DAY + HOURLY_DAILY_DISTRIBUTION_HOUR + HOURLY_DAILY_DISTRIBUTION_MIN,
                                                                    :end_time => @monday_start + @count_weeks * IceCube::ONE_WEEK)
      periodicity_hourly_daily_distribution.add_recurrence_rule IceCube::Rule.weekly.until(@monday_start + @count_weeks * IceCube::ONE_WEEK)

      periodicity_behaviour = IceCube::Schedule.new(@monday_start + BEHAVIOUR_DAY + BEHAVIOUR_HOUR,
                                                    :end_time => @monday_start + @count_weeks * IceCube::ONE_WEEK)
      periodicity_behaviour.add_recurrence_rule IceCube::Rule.weekly.until(@monday_start + @count_weeks * IceCube::ONE_WEEK)

      periodicity_device_platform_plugin = IceCube::Schedule.new(@monday_start + DEVICE_PLATFORM_PLUGIN_DAY + DEVICE_PLATFORM_PLUGIN_HOUR + DEVICE_PLATFORM_PLUGIN_MIN,
                                                                 :end_time => @monday_start + @count_weeks * IceCube::ONE_WEEK)
      periodicity_device_platform_plugin.add_recurrence_rule IceCube::Rule.weekly.until(@monday_start + @count_weeks * IceCube::ONE_WEEK)

      periodicity_device_platform_resolution = IceCube::Schedule.new(@monday_start + DEVICE_PLATFORM_RESOLUTION_DAY + DEVICE_PLATFORM_RESOLUTION_HOUR,
                                                                     :end_time => @monday_start + @count_weeks * IceCube::ONE_WEEK)
      periodicity_device_platform_resolution.add_recurrence_rule IceCube::Rule.weekly.until(@monday_start + @count_weeks * IceCube::ONE_WEEK)


      business.merge!({"profil_id_ga" => @profil_id_ga}) if @statistics_type == :ga

      @events += [
          Event.new("Scraping_device_platform_plugin",
                    periodicity_device_platform_plugin,
                    {
                        :policy_type => @policy_type,
                        :policy_id => @policy_id,
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :statistic_type => @statistics_type
                    }),
          Event.new("Scraping_device_platform_resolution",
                    periodicity_device_platform_resolution,
                    {
                        :policy_type => @policy_type,
                        :policy_id => @policy_id,
                        :website_label => @website_label,
                        :website_id => @website_id,
                        :statistic_type => @statistics_type
                    }),
          Event.new("Scraping_hourly_daily_distribution",
                    periodicity_hourly_daily_distribution,
                    @statistics_type == :custom ?
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
                    periodicity_behaviour,
                    @statistics_type == :custom ?
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
                        }
          )

      ]
    end

  end

end