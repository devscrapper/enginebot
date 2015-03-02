require_relative '../../../model/planning/event'

module Planning

  class Objective
    CHOOSING_LANDING_PAGES_DAY = -1 * IceCube::ONE_DAY
    CHOOSING_LANDING_PAGES_HOUR = 3 * IceCube::ONE_HOUR #heure de démarrage est 3h du matin
    CHOOSING_DEVICE_PLATFORM_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
    CHOOSING_DEVICE_PLATFORM_HOUR = 4 * IceCube::ONE_HOUR #heure de démarrage est 4h du matin
    BUILDING_VISITS_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
    BUILDING_VISITS_HOUR = 5 * IceCube::ONE_HOUR #heure de démarrage est 4h du matin
    START_PUBLISHING_VISITS_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
    START_PUBLISHING_VISITS_HOUR = 22 * IceCube::ONE_HOUR #heure de démarrage est 10h du soir
    END_PUBLISHING_VISITS_DAY = 0 * IceCube::ONE_DAY #on decale d'un  jour j-1
    END_PUBLISHING_VISITS_HOUR = 21 * IceCube::ONE_HOUR #heure d'arret est 9h du soir du lendemain
    # si le décalage du publishnig change, il faut penser à corriger en conséquence le décalage dans la méthode model/building/visits.rb/Publishing_visits_by_hour()
    attr :count_visits,
         :label,
         :building_date,
         :visit_bounce_rate,
         :page_views_per_visit,
         :avg_time_on_site,
         :min_durations,
         :min_pages,
         :hourly_distribution,
         :return_visitor_rate,
         :direct_medium_percent,
         :organic_medium_percent,
         :referral_medium_percent,
         :advertising_percent,
         :advertisers,
         :url_root


    def initialize(data)
      @count_visits = data["count_visits"]
      @building_date = data["building_date"].to_s
      @label = data["label"]
      @visit_bounce_rate = data["visit_bounce_rate"]
      @page_views_per_visit = data["page_views_per_visit"]
      @avg_time_on_site = data["avg_time_on_site"]
      @min_durations= data["min_durations"]
      @min_pages = data["min_pages"]
      @hourly_distribution = data["hourly_distribution"]
      @return_visitor_rate = data["return_visitor_rate"]
      @direct_medium_percent=data["direct_medium_percent"]
      @organic_medium_percent=data["organic_medium_percent"]
      @referral_medium_percent= data["referral_medium_percent"]
      @advertising_percent= data["advertising_percent"]
      @advertisers = data["advertisers"]
      @periodicity = data["periodicity"]
      @url_root = data["url_root"]
    end

    def to_event
      date_objective = IceCube::Schedule.from_yaml(@periodicity).start_time
      key = {"building_date" => @building_date,
             "label" => @label
      }
      business = {
          "label" => @label,
          "count_visits" => @count_visits
      }

      start_time = date_objective + CHOOSING_DEVICE_PLATFORM_DAY + CHOOSING_DEVICE_PLATFORM_HOUR
      periodicity = IceCube::Schedule.new(start_time, :end_time => start_time)
      periodicity.add_recurrence_rule IceCube::Rule.daily.until(date_objective + CHOOSING_DEVICE_PLATFORM_DAY + CHOOSING_DEVICE_PLATFORM_HOUR)
      choosing_device_platform_event = Event.new(key,
                                                 "Choosing_device_platform",
                                                 periodicity.to_yaml,
                                                 business)


      business = {
          "label" => @label,
          "count_visits" => @count_visits,
          "direct_medium_percent" => @direct_medium_percent,
          "organic_medium_percent" => @organic_medium_percent,
          "referral_medium_percent" => @referral_medium_percent

      }


      start_time = date_objective + CHOOSING_LANDING_PAGES_DAY + CHOOSING_LANDING_PAGES_HOUR
      periodicity = IceCube::Schedule.new(start_time, :end_time => start_time)
      periodicity.add_recurrence_rule IceCube::Rule.daily.until(date_objective + CHOOSING_LANDING_PAGES_DAY + CHOOSING_LANDING_PAGES_HOUR)
      choosing_landing_page_event = Event.new(key,
                                              "Choosing_landing_pages",
                                              periodicity.to_yaml,
                                              business)


      business = {
          "label" => @label,
          "count_visits" => @count_visits,
          "visit_bounce_rate" => @visit_bounce_rate,
          "page_views_per_visit" => @page_views_per_visit,
          "avg_time_on_site" => @avg_time_on_site,
          "min_durations" => @min_durations,
          "min_pages" => @min_pages,
          "hourly_distribution" => @hourly_distribution,
          "return_visitor_rate" => @return_visitor_rate,
          "advertisers" => @advertisers,
          "advertising_percent" => @advertising_percent
      }

      start_time = date_objective + BUILDING_VISITS_DAY + BUILDING_VISITS_HOUR
      periodicity = IceCube::Schedule.new(start_time, :end_time => start_time)
      periodicity.add_recurrence_rule IceCube::Rule.daily.until(date_objective + BUILDING_VISITS_DAY + BUILDING_VISITS_HOUR)
      building_visits_event = Event.new(key,
                                        "Building_visits",
                                        periodicity.to_yaml,
                                        business)

      business = {
          "label" => @label}


      periodicity = IceCube::Schedule.new(date_objective + START_PUBLISHING_VISITS_DAY + START_PUBLISHING_VISITS_HOUR,
                                          :end_time => date_objective + END_PUBLISHING_VISITS_DAY + END_PUBLISHING_VISITS_HOUR)
      periodicity.add_recurrence_rule IceCube::Rule.hourly.until(date_objective + END_PUBLISHING_VISITS_DAY + END_PUBLISHING_VISITS_HOUR)
      publishing_visits_event = Event.new(key,
                                          "Publishing_visits",
                                          periodicity.to_yaml,
                                          business)
      [choosing_device_platform_event, choosing_landing_page_event, building_visits_event, publishing_visits_event]
    end
  end
end