require_relative '../event'
require_relative 'policy'

module Planning

  class Rank < Policy

    attr :count_visits_per_day

    def initialize(data)
      super(data)
      @count_visits_per_day = data["count_visits_per_day"]
    end

    def to_event

      key = {"policy_id" => @policy_id,
             "label" => @label}


      #Si demande suppression de la policy alors absence de periodicity et de business_building_objectives
      if @count_weeks.nil? and @monday_start.nil?
        [Event.new(key,
                   "Building_objectives"),
         Event.new(key,
                   "Building_landing_pages_organic")]

      else
        periodicity_building_objectives = IceCube::Schedule.new(@monday_start + BUILDING_OBJECTIVES_DAY + BUILDING_OBJECTIVES_HOUR,
                                                                :end_time => @monday_start + @count_weeks * IceCube::ONE_WEEK)
        periodicity_building_objectives.add_recurrence_rule IceCube::Rule.weekly.until(@monday_start + @count_weeks * IceCube::ONE_WEEK)

        business_building_objectives = {
            "label" => @label,
            "count_visits_per_day" => @count_visits_per_day,
            "website_id" => @website_id,
            "policy_id" => @policy_id,
            "policy" => :rank
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
                   "Building_landing_pages_organic",
                   periodicity_building_landing_pages.to_yaml,
                   business_building_landing_pages)]
      end


    end
  end


end