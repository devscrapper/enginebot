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
        raise "#{delay} day(s) remaining before start policy, it is too short to prepare #{@policy_type} policy, #{DELAY_TO_PREPARE} day(s) are require !" if delay < DELAY_TO_PREPARE
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
        @building_landing_pages_organic_day = parameters.building_landing_pages_organic_day
        @building_landing_pages_organic_hour = parameters.building_landing_pages_organic_hour
        @building_landing_pages_organic_min = parameters.building_landing_pages_organic_min


      end
    end

  end


end