require_relative '../event'
require_relative 'policy'

module Planning

  class Rank < Policy

    attr :count_visits_per_day

    def initialize(data)
      super(data)
      @count_visits_per_day = data[:count_visits_per_day]
    end

    def to_event

      key = {"policy_id" => @policy_id}


      #Si demande suppression de la policy alors absence de periodicity et de business_building_objectives
      if @count_weeks.nil? and @monday_start.nil?
        [
            Event.new(key, "Building_objectives", nil, {"website_label" => @website_label}),
            Event.new(key, "Building_landing_pages_organic", nil, {"website_label" => @website_label}),
            Event.new(key, "Choosing_device_platform", nil, {"website_label" => @website_label}),
            Event.new(key, "Choosing_landing_pages", nil, {"website_label" => @website_label}),
            Event.new(key, "Building_visits", nil, {"website_label" => @website_label}),
            Event.new(key, "Publishing_visits", nil, {"website_label" => @website_label})
        ]

      else
        periodicity_building_objectives = IceCube::Schedule.new(@monday_start + BUILDING_OBJECTIVES_DAY + BUILDING_OBJECTIVES_HOUR,
                                                                :end_time => @monday_start + @count_weeks * IceCube::ONE_WEEK)
        periodicity_building_objectives.add_recurrence_rule IceCube::Rule.weekly.until(@monday_start + @count_weeks * IceCube::ONE_WEEK)


        business_building_objectives ={
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
            "policy_type" => :rank
        }

        periodicity_building_landing_pages = IceCube::Schedule.new(@monday_start + BUILDING_MATRIX_AND_PAGES_DAY + BUILDING_MATRIX_AND_PAGES_HOUR,
                                                                   :end_time => @monday_start + @count_weeks * IceCube::ONE_WEEK)
        periodicity_building_landing_pages.add_recurrence_rule IceCube::Rule.daily

        business_building_landing_pages = {
            "website_label" => @website_label,
            "website_id" => @website_id,
            "policy_id" => @policy_id,
            "policy_type" => :rank
        }

        [Event.new(key,
                   "Building_objectives",
                   periodicity_building_objectives.to_yaml,
                   business_building_objectives),
         Event.new(key,
                   "Building_landing_pages_organic",
                   periodicity_building_landing_pages.to_yaml,
                   business_building_landing_pages)]
      end


    end
  end


end