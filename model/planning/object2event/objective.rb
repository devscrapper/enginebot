require_relative '../event'

module Planning

  class Objective
    EVALUATING_LANDING_PAGE_KEYWORD_DAY = -1 * IceCube::ONE_DAY #on decale de 2 jour j-1
    EVALUATING_LANDING_PAGE_KEYWORD_HOUR = 0 * IceCube::ONE_HOUR #heure de démarrage est 0h du matin
    EVALUATING_LANDING_PAGE_BACKLINK_DAY = -1 * IceCube::ONE_DAY #on decale de 2 jour j-1
    EVALUATING_LANDING_PAGE_BACKLINK_HOUR = 1 * IceCube::ONE_HOUR #heure de démarrage est 1h du matin

    CHOOSING_LANDING_PAGES_DAY = -1 * IceCube::ONE_DAY
    CHOOSING_LANDING_PAGES_HOUR = 0 * IceCube::ONE_HOUR #heure de démarrage est 3h du matin
    CHOOSING_DEVICE_PLATFORM_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
    CHOOSING_DEVICE_PLATFORM_HOUR = 0 * IceCube::ONE_HOUR #heure de démarrage est 0h du matin
    BUILDING_VISITS_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
    BUILDING_VISITS_HOUR = 0 * IceCube::ONE_HOUR #heure de démarrage est 4h du matin
    BUILDING_PLANIFICATION_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
    BUILDING_PLANIFICATION_HOUR = 0 * IceCube::ONE_HOUR #heure de démarrage est 4h du matin
    EXTENDING_VISITS_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
    EXTENDING_VISITS_HOUR =0 * IceCube::ONE_HOUR #heure de démarrage est 4h du matin
    START_PUBLISHING_VISITS_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
    START_PUBLISHING_VISITS_HOUR = 22 * IceCube::ONE_HOUR #heure de démarrage est 10h du soir
    END_PUBLISHING_VISITS_DAY = 0 * IceCube::ONE_DAY #on decale d'un  jour j-1
    END_PUBLISHING_VISITS_HOUR = 21 * IceCube::ONE_HOUR #heure d'arret est 9h du soir du lendemain
    # si le décalage du publishnig change, il faut penser à corriger en conséquence le décalage dans la méthode model/building/visits.rb/Publishing_visits_by_hour()
    attr :count_visits,
         :website_label,
         :building_date,
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
         :date_objective,
         :key,
         :events


    def initialize(data)
      @policy_id = data[:policy_id]
      @policy_type = data[:policy_type]
      @count_weeks = data[:count_weeks]
      @objective_id = data[:objective_id]
      @count_visits = data[:count_visits]
      @building_date = data[:building_date].to_s
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
      @start_time = IceCube::Schedule.from_yaml(@periodicity).start_time
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
      @key = {
          "policy_id" => @policy_id,
          "building_date" => @building_date
      }
      @date_objective = IceCube::Schedule.from_yaml(@periodicity).start_time
      @events = []
    end

    def to_event
      if @organic_medium_percent > 0

        periodicity_organic = IceCube::Schedule.new(@date_objective +
                                                        EVALUATING_LANDING_PAGE_KEYWORD_DAY +
                                                        EVALUATING_LANDING_PAGE_KEYWORD_HOUR,
                                                    :end_time => @date_objective +
                                                        EVALUATING_LANDING_PAGE_KEYWORD_DAY +
                                                        EVALUATING_LANDING_PAGE_KEYWORD_HOUR)
        periodicity_organic.add_recurrence_rule IceCube::Rule.daily.until(date_objective + EVALUATING_LANDING_PAGE_KEYWORD_DAY + EVALUATING_LANDING_PAGE_KEYWORD_HOUR)

        @events << Event.new(key,
                             "Evaluating_traffic_source_organic",
                             {
                                 "periodicity" => periodicity_organic.to_yaml,
                                 "business" => {
                                     "website_label" => @website_label,
                                     "objective_id" => @objective_id,
                                     "policy_id" => @policy_id,
                                     "policy_type" => @policy_type,
                                     "website_id" => @website_id,
                                     "count_max" => ((@organic_medium_percent * @count_visits / 100) * 1.2).round(0), # ajout de 20% de mot clé pour eviter les manques
                                     "url_root" => @url_root
                                 }
                             })

      end

      # permet de ne pas planifier un event sur evaluating referral pour la policy Rank et de maière generale de gagner du temps
      if @referral_medium_percent > 0

        periodicity_referral = IceCube::Schedule.new(date_objective +
                                                         EVALUATING_LANDING_PAGE_BACKLINK_DAY +
                                                         EVALUATING_LANDING_PAGE_BACKLINK_HOUR,
                                                     :end_time => date_objective +
                                                         EVALUATING_LANDING_PAGE_BACKLINK_DAY +
                                                         EVALUATING_LANDING_PAGE_BACKLINK_HOUR)

        periodicity_referral.add_recurrence_rule IceCube::Rule.daily.until(date_objective +
                                                                               EVALUATING_LANDING_PAGE_KEYWORD_DAY +
                                                                               EVALUATING_LANDING_PAGE_KEYWORD_HOUR)

        @events << Event.new(key,
                             "Evaluating_traffic_source_referral",
                             {
                                 "periodicity" => periodicity_referral.to_yaml,
                                 "business" => {
                                     "website_label" => @website_label,
                                     "objective_id" => @objective_id,
                                     "policy_id" => @policy_id,
                                     "policy_type" => @policy_type,
                                     "count_max" => ((@referral_medium_percent * @count_visits / 100) * 1.2).round(0), # ajout de 20% de mot clé pour eviter les manques
                                     "url_root" => @url_root
                                 }
                             })

      end

      @events += [

                  Event.new(@key,
                            "Building_landing_pages_organic",
                            {
                                "pre_tasks" => ["Evaluating_traffic_source_organic"],
                                # "periodicity" => IceCube::Schedule.new(@monday_start +
                                #                                            BUILDING_LANDING_PAGES_ORGANIC_DAY +
                                #                                            BUILDING_LANDING_PAGES_ORGANIC_HOUR,
                                #                                        :end_time => @monday_start +
                                #                                            BUILDING_LANDING_PAGES_ORGANIC_DAY +
                                #                                            BUILDING_LANDING_PAGES_ORGANIC_HOUR +
                                #                                            @count_weeks * IceCube::ONE_WEEK).to_yaml,
                                "business" => {
                                    "website_label" => @website_label,
                                    "website_id" => @website_id,
                                    "policy_id" => @policy_id,
                                    "policy_type" => @policy_type
                                }
                            }),

                  Event.new(@key,
                            "Building_landing_pages_referral",
                            {
                                "pre_tasks" => ["Evaluating_traffic_source_referral"],
                                # "periodicity" => IceCube::Schedule.new(@monday_start +
                                #                                            BUILDING_LANDING_PAGES_REFERRAL_DAY +
                                #                                            BUILDING_LANDING_PAGES_REFERRAL_HOUR,
                                #                                        :end_time => @monday_start +
                                #                                            BUILDING_LANDING_PAGES_REFERRAL_DAY +
                                #                                            BUILDING_LANDING_PAGES_REFERRAL_HOUR +
                                #                                            @count_weeks * IceCube::ONE_WEEK).to_yaml,
                                "business" => {
                                    "website_label" => @website_label,
                                    "website_id" => @website_id,
                                    "policy_id" => @policy_id,
                                    "policy_type" => @policy_type
                                }
                            }),
          Event.new(key,
                    "Choosing_landing_pages",
                    {
                        "pre_tasks" => ["Building_landing_pages_direct",
                                        "Building_landing_pages_organic",
                                        "Building_landing_pages_referral"],
                        # "periodicity" => IceCube::Schedule.new(@start_time +
                        #                                            CHOOSING_LANDING_PAGES_DAY +
                        #                                            CHOOSING_LANDING_PAGES_HOUR,
                        #                                        :end_time => @start_time +
                        #                                            CHOOSING_LANDING_PAGES_DAY +
                        #                                            CHOOSING_LANDING_PAGES_HOUR +
                        #                                            @count_weeks * IceCube::ONE_WEEK).to_yaml,
                        "business" => {
                            "policy_id" => @policy_id,
                            "date_building" => @building_date,
                            "policy_type" => @policy_type,
                            "objective_id" => @objective_id,
                            "website_label" => @website_label,
                            "count_visits" => @count_visits,
                            "direct_medium_percent" => @direct_medium_percent,
                            "organic_medium_percent" => @organic_medium_percent,
                            "referral_medium_percent" => @referral_medium_percent

                        }
                    }),
          Event.new(key,
                    "Building_visits",
                    {
                        "pre_tasks" => ["Choosing_landing_pages"],
                        # "periodicity" => IceCube::Schedule.new(@start_time +
                        #                                            BUILDING_VISITS_DAY +
                        #                                            BUILDING_VISITS_HOUR,
                        #                                        :end_time => @start_time +
                        #                                            BUILDING_VISITS_DAY +
                        #                                            BUILDING_VISITS_HOUR +
                        #                                            @count_weeks * IceCube::ONE_WEEK).to_yaml,
                        "business" => {
                            "objective_id" => @objective_id,
                            "website_label" => @website_label,
                            "date_building" => @building_date,
                            "policy_type" => @policy_type,
                            "website_id" => @website_id,
                            "policy_id" => @policy_id,
                            "count_visits" => @count_visits,
                            "visit_bounce_rate" => @visit_bounce_rate,
                            "page_views_per_visit" => @page_views_per_visit,
                            "avg_time_on_site" => @avg_time_on_site,
                            "min_durations" => @min_durations,
                            "min_pages" => @min_pages,
                        }
                    }),
          Event.new(key,
                    "Building_planification",
                    {
                        "pre_tasks" => ["Building_visits"],
                        # "periodicity" => IceCube::Schedule.new(@start_time +
                        #                                            BUILDING_PLANIFICATION_DAY +
                        #                                            BUILDING_PLANIFICATION_HOUR,
                        #                                        :end_time => @start_time +
                        #                                            BUILDING_PLANIFICATION_DAY +
                        #                                            BUILDING_PLANIFICATION_HOUR +
                        #                                            @count_weeks * IceCube::ONE_WEEK).to_yaml,
                        "business" => {
                            "objective_id" => @objective_id,
                            "website_label" => @website_label,
                            "date_building" => @building_date,
                            "policy_type" => @policy_type,
                            "website_id" => @website_id,
                            "policy_id" => @policy_id,
                            "count_visits" => @count_visits,
                            "hourly_distribution" => @hourly_distribution
                        }
                    }),
          Event.new(key,
                    "Extending_visits",
                    {
                        "pre_tasks" => ["Building_planification",
                                        "Choosing_device_platform"],
                        # "periodicity" => IceCube::Schedule.new(@start_time +
                        #                                            EXTENDING_VISITS_DAY +
                        #                                            EXTENDING_VISITS_HOUR,
                        #                                        :end_time => @start_time +
                        #                                            EXTENDING_VISITS_DAY +
                        #                                            EXTENDING_VISITS_HOUR +
                        #                                            @count_weeks * IceCube::ONE_WEEK).to_yaml,
                        "business" => {
                            "objective_id" => @objective_id,
                            "website_label" => @website_label,
                            "date_building" => @building_date,
                            "policy_type" => @policy_type,
                            "website_id" => @website_id,
                            "policy_id" => @policy_id,
                            "count_visits" => @count_visits,
                            "advertising_percent" => @advertising_percent,
                            "advertisers" => @advertisers
                        }
                    })
      ]


      periodicity = IceCube::Schedule.new(@start_time + CHOOSING_DEVICE_PLATFORM_DAY + CHOOSING_DEVICE_PLATFORM_HOUR,
                                          :end_time => @start_time + CHOOSING_DEVICE_PLATFORM_DAY + CHOOSING_DEVICE_PLATFORM_HOUR)
      periodicity.add_recurrence_rule IceCube::Rule.daily.until(@start_time + CHOOSING_DEVICE_PLATFORM_DAY + CHOOSING_DEVICE_PLATFORM_HOUR)

      @events << Event.new(key,
                           "Choosing_device_platform",
                           {
                               "pre_tasks" => ["Building_device_platform"],
                               # "periodicity" => periodicity.to_yaml,
                               "business" => {
                                   "policy_id" => @policy_id,
                                   "date_building" => @building_date,
                                   "policy_type" => @policy_type,
                                   "objective_id" => @objective_id,
                                   "website_label" => @website_label,
                                   "count_visits" => @count_visits
                               }
                           })

      periodicity = IceCube::Schedule.new(@start_time + START_PUBLISHING_VISITS_DAY + START_PUBLISHING_VISITS_HOUR,
                                          :end_time => @start_time + END_PUBLISHING_VISITS_DAY + END_PUBLISHING_VISITS_HOUR)
      periodicity.add_recurrence_rule IceCube::Rule.hourly.until(@start_time + END_PUBLISHING_VISITS_DAY + END_PUBLISHING_VISITS_HOUR)
      @events << Event.new(key,
                           "Publishing_visits",
                           {
                               "periodicity" => periodicity.to_yaml,
                               "business" => {
                                   "objective_id" => @objective_id,
                                   "website_label" => @website_label,
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
                                   "max_duration" => @max_duration
                               }
                           })


      @events
    end
  end
end