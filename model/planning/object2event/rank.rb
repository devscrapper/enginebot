require_relative '../event'
require_relative 'policy'

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
    end

    def to_event


      #Si demande suppression de la policy alors absence de periodicity et de business_building_objectives
      if @count_weeks.nil? and @monday_start.nil?
        @events += [
            Event.new(@key, "Building_objectives"),
            Event.new(@key, "Building_landing_pages_organic"),
            Event.new(@key, "Choosing_device_platform"),
            Event.new(@key, "Choosing_landing_pages"),
            Event.new(@key, "Building_visits"),
            Event.new(@key, "Publishing_visits"),
            Event.new(@key, "Scraping_traffic_source_organic"),
            Event.new(@key, "Evaluating_traffic_source_organic")
        ]

      else

        periodicity_traffic_source_organic = IceCube::Schedule.new(@registering_time +
                                                                       TRAFFIC_SOURCE_KEYWORDS_DAY +
                                                                       TRAFFIC_SOURCE_KEYWORDS_HOUR,
                                                                   :end_time => @registering_time +
                                                                       @count_weeks * IceCube::ONE_WEEK)
        periodicity_traffic_source_organic.add_recurrence_rule IceCube::Rule.monthly.until(@registering_time +
                                                                                               @count_weeks * IceCube::ONE_WEEK)

        @events << Event.new(@key,
                             "Scraping_traffic_source_organic",
                             {

                                 "periodicity" => periodicity_traffic_source_organic.to_yaml,
                                 "business" => {
                                     "policy_type" => @policy_type,
                                     "policy_id" => @policy_id,
                                     "website_label" => @website_label,
                                     "url_root" => @url_root,
                                     "website_id" => @website_id,
                                     "keywords" => @keywords
                                 }
                             })


        periodicity_building_objectives = IceCube::Schedule.new(@monday_start + BUILDING_OBJECTIVES_DAY + BUILDING_OBJECTIVES_HOUR,
                                                                :end_time => @monday_start + @count_weeks * IceCube::ONE_WEEK)
        periodicity_building_objectives.add_recurrence_rule IceCube::Rule.weekly.until(@monday_start + @count_weeks * IceCube::ONE_WEEK)

        @events << Event.new(@key,
                             "Building_objectives",
                             {
                                 "pre_tasks" => ["Building_hourly_daily_distribution", "Building_behaviour"],
                                 "periodicity" => periodicity_building_objectives.to_yaml,
                                 "business" => {
                                     "count_visits_per_day" => @count_visits_per_day,
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
                             })


        periodicity_building_landing_pages = IceCube::Schedule.new(@monday_start + BUILDING_MATRIX_AND_PAGES_DAY + BUILDING_MATRIX_AND_PAGES_HOUR,
                                                                   :end_time => @monday_start + @count_weeks * IceCube::ONE_WEEK)
        periodicity_building_landing_pages.add_recurrence_rule IceCube::Rule.daily

        @events << Event.new(@key,
                             "Building_landing_pages_direct",
                             {
                                 "pre_tasks" => ["scraping_website"],

                                 "periodicity" => periodicity_building_landing_pages.to_yaml,
                                 "business" => {
                                     "website_label" => @website_label,
                                     "website_id" => @website_id,
                                     "policy_id" => @policy_id,
                                     "policy_type" => @policy_type
                                 }
                             })
      end

      @events
    end
  end


end