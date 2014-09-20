require_relative '../../../model/planning/event'

module Planning

  class Policy
    BUILDING_OBJECTIVES_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
    BUILDING_OBJECTIVES_HOUR = 2 * IceCube::ONE_HOUR #heure de démarrage est 2h du matin
    attr :label,
         :change_count_visits_percent,
         :change_bounce_visits_percent,
         :direct_medium_percent,
         :organic_medium_percent,
         :referral_medium_percent,
         :advertising_percent,
         :advertisers,
         :website_id,
         :policy_id,
         :count_weeks

    def initialize(data)
      @label = data["label"]
      @monday_start = Time.local(data["monday_start"].year, data["monday_start"].month, data["monday_start"].day) unless data["monday_start"].nil? # iceCube a besoin d'un Time et pas d'un Date
      @count_weeks = data["count_weeks"]
      @change_count_visits_percent = data["change_count_visits_percent"]
      @change_bounce_visits_percent = data["change_bounce_visits_percent"]
      @direct_medium_percent=data["direct_medium_percent"]
      @organic_medium_percent=data["organic_medium_percent"]
      @referral_medium_percent= data["referral_medium_percent"]
      @advertising_percent= data["advertising_percent"]
      @advertisers = YAML::load(data["advertisers"])
      @website_id=data["website_id"]
      @policy_id=data["policy_id"]
    end

    def to_event

      key = {"policy_id" => @policy_id}


      #Si demande suppression de la policy alors absence de periodicity et de business
      if @count_weeks.nil? and @monday_start.nil?
        Event.new(key,
                  "Building_objectives")
      else
        periodicity = IceCube::Schedule.new(@monday_start + BUILDING_OBJECTIVES_DAY + BUILDING_OBJECTIVES_HOUR,
                                                                      :end_time => @monday_start + @count_weeks * IceCube::ONE_WEEK)
        periodicity.add_recurrence_rule IceCube::Rule.weekly.until(@monday_start + @count_weeks * IceCube::ONE_WEEK)

        business = {
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
        }

        [Event.new(key,
                  "Building_objectives",
                  periodicity.to_yaml,
                  business)]
      end


    end
  end


end