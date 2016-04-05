require_relative 'policy'
require_relative '../../../lib/parameter'

module Planning

  class Rank < Policy

    DELAY_TO_PREPARE = 1

    attr :count_visits_per_day,
         :keywords

    def initialize(data)
      super(data)
      @count_visits_per_day = data[:count_visits_per_day]
      @policy_type = "rank"
      @keywords = data[:keywords]
      unless data[:monday_start].nil? # iceCube a besoin d'un Time et pas d'un Date
        delay = (@monday_start.to_date - Time.now.to_date).to_i
        raise "#{delay} day(s) remaining before start policy, it is too short to prepare #{@policy_type} policy, #{DELAY_TO_PREPARE} day(s) are require !" if delay <= DELAY_TO_PREPARE
      end

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
      super
      periodicity_scraping_traffic_source_organic = IceCube::Schedule.new(@registering_date + @scraping_traffic_source_organic_day * IceCube::ONE_DAY +
                                                                              @scraping_traffic_source_organic_hour * IceCube::ONE_HOUR +
                                                                              @scraping_traffic_source_organic_min * IceCube::ONE_MINUTE,
                                                                          :end_time => @registering_date +
                                                                              @count_weeks * IceCube::ONE_WEEK)

      periodicity_scraping_traffic_source_organic.add_recurrence_rule IceCube::Rule.monthly.until(@registering_date +
                                                                                                      @count_weeks * IceCube::ONE_WEEK)

      periodicity_building_objectives = IceCube::Schedule.new(@monday_start +
                                                                  @building_objectives_day * IceCube::ONE_DAY +
                                                                  @building_objectives_hour * IceCube::ONE_HOUR +
                                                                  @building_objectives_min * IceCube::ONE_MINUTE,
                                                              :end_time => @monday_start +
                                                                  (@count_weeks -1) * IceCube::ONE_WEEK)

      periodicity_building_objectives.add_recurrence_rule IceCube::Rule.weekly.until(@monday_start +
                                                                                         (@count_weeks -1) * IceCube::ONE_WEEK)
      @events += [
          Event.new("Scraping_traffic_source_organic",
                    periodicity_scraping_traffic_source_organic,
                    @execution_mode,
                    {
                        :policy_type => @policy_type,
                        :policy_id => @policy_id,
                        :website_label => @website_label,
                        :url_root => @url_root,
                        :keywords => @keywords,
                        :website_id => @website_id
                    }),
          Event.new("Building_objectives",
                    periodicity_building_objectives,
                    {
                        :website_id => @website_id,
                        :website_label => @website_label,
                        :policy_type => @policy_type,
                        :policy_id => @policy_id,
                        :change_bounce_visits_percent => @change_bounce_visits_percent,
                        :monday_start => @monday_start,
                        :count_weeks => @count_weeks,
                        :url_root => @url_root,
                        :count_visits_per_day => @count_visits_per_day,
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
                    [@building_hourly_daily_distribution, @building_behaviour])
      ]
    end

  end


end