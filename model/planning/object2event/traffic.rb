require_relative 'policy'

module Planning

  class Traffic < Policy

    attr :change_count_visits_percent,
         :change_bounce_visits_percent,
         :direct_medium_percent,
         :organic_medium_percent,
         :referral_medium_percent,
         :advertising_percent,
         :advertisers

    def initialize(data)
      super(data)
      @change_count_visits_percent = data["change_count_visits_percent"]
      @change_bounce_visits_percent = data["change_bounce_visits_percent"]
      @direct_medium_percent=data["direct_medium_percent"]
      @organic_medium_percent=data["organic_medium_percent"]
      @referral_medium_percent= data["referral_medium_percent"]
      @advertising_percent= data["advertising_percent"]
      @advertisers = YAML::load(data["advertisers"]) unless data["advertisers"].nil?
    end

    def to_event

      key = {"policy_id" => @policy_id,
             "label" => @label}


      #Si demande suppression de la policy alors absence de periodicity et de business_building_objectives
      if @count_weeks.nil? and @monday_start.nil?
        [Event.new(key,
                   "Building_objectives"),
         Event.new(key,
                   "Building_landing_pages_direct"),
         Event.new(key,
                   "Building_landing_pages_organic"),
         Event.new(key,
                   "Building_landing_pages_referral")]

      else
        periodicity_building_objectives = IceCube::Schedule.new(@monday_start + BUILDING_OBJECTIVES_DAY + BUILDING_OBJECTIVES_HOUR,
                                                                :end_time => @monday_start + @count_weeks * IceCube::ONE_WEEK)
        periodicity_building_objectives.add_recurrence_rule IceCube::Rule.weekly.until(@monday_start + @count_weeks * IceCube::ONE_WEEK)

        business_building_objectives = {
            "label" => @label,
            "change_count_visits_percent" => @change_count_visits_percent,
            "change_bounce_visits_percent" => @change_bounce_visits_percent,
            "direct_medium_percent" => @direct_medium_percent,
            "organic_medium_percent" => @organic_medium_percent,
            "referral_medium_percent" => @referral_medium_percent,
            "advertising_percent" => @advertising_percent,
            "advertisers" => @advertisers,
            "website_id" => @website_id,
            "policy_id" => @policy_id,
            "policy" => :traffic
        }

        periodicity_building_landing_pages = IceCube::Schedule.new(@monday_start + BUILDING_MATRIX_AND_PAGES_DAY + BUILDING_MATRIX_AND_PAGES_HOUR,
                                                                   :end_time => @monday_start + @count_weeks * IceCube::ONE_WEEK)
        periodicity_building_landing_pages.add_recurrence_rule IceCube::Rule.daily

        business_building_landing_pages = {
            "label" => @label
        }

        [Event.new(key,
                   "Building_objectives",
                   periodicity_building_objectives.to_yaml,
                   business_building_objectives),
         Event.new(key,
                   "Building_landing_pages_direct",
                   periodicity_building_landing_pages.to_yaml,
                   business_building_landing_pages),
         Event.new(key,
                   "Building_landing_pages_organic",
                   periodicity_building_landing_pages.to_yaml,
                   business_building_landing_pages),
         Event.new(key,
                   "Building_landing_pages_referral",
                   periodicity_building_landing_pages.to_yaml,
                   business_building_landing_pages)]
      end


    end
  end


end