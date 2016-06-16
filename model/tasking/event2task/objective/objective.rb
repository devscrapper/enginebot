require 'ice_cube'
require 'uuid'


module Tasking
  module Objective
    class Objective
      class ObjectiveException < StandardError
      end
      SEPARATOR4="|"

      attr :website_label,
           :count_visits,
           :visit_bounce_rate,
           :avg_time_on_site,
           :page_views_per_visit,
           :min_durations,
           :min_pages,
           :direct_medium_percent,
           :referral_medium_percent,
           :organic_medium_percent,
           :advertising_percent,
           :advertisers,
           :url_root,
           :hourly_distribution,
           :periodicity,
           :policy_id, :website_id, :policy_type, :count_weeks,
           :objective_id,
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
           :execution_mode,
           :fqdn_advertisings

      def initialize(website_label,
                     date,
                     count_visits =nil,
                     visit_bounce_rate=nil,
                     avg_time_on_site=nil,
                     page_views_per_visit=nil,
                     min_durations=nil,
                     min_pages=nil,
                     direct_medium_percent=nil,
                     referral_medium_percent=nil,
                     organic_medium_percent=nil,
                     advertising_percent=nil,
                     advertisers = nil,
                     url_root = nil,
                     hourly_distribution=nil,
                     policy_id, website_id, policy_type, count_weeks, execution_mode,
                     min_count_page_advertiser,
                     max_count_page_advertiser,
                     min_duration_page_advertiser,
                     max_duration_page_advertiser,
                     percent_local_page_advertiser,
                     duration_referral,
                     min_count_page_organic,
                     max_count_page_organic,
                     min_duration_page_organic,
                     max_duration_page_organic,
                     min_duration,
                     max_duration,
                     fqdn_advertisings)
        @objective_id = UUID.generate(:compact)
        @website_label = website_label
        @count_visits = count_visits
        @visit_bounce_rate=visit_bounce_rate
        @avg_time_on_site=avg_time_on_site
        @page_views_per_visit=page_views_per_visit
        @min_durations=min_durations
        @min_pages=min_pages
        @direct_medium_percent=direct_medium_percent
        @referral_medium_percent=referral_medium_percent
        @organic_medium_percent=organic_medium_percent
        @advertising_percent=advertising_percent
        @advertisers = advertisers
        @url_root = url_root
        if date.is_a?(Date)
          # pour Traffic et Rank, l'objectif est planififé par rapport à une date
          end_time = start_time = Time.local(date.year, date.month, date.day)
        else
          # pour SeaAttack, l'objectif est panifié par rapport à un Time our delcenche maintenant
          end_time = start_time = date
        end
        @periodicity =IceCube::Schedule.new(start_time,
                                            :end_time => end_time).to_yaml
        @hourly_distribution=translate_to_count_visits_target(hourly_distribution, count_visits)
        @policy_id = policy_id
        @policy_type = policy_type
        @website_id = website_id
        @count_weeks = count_weeks
        @execution_mode=execution_mode
        @min_count_page_advertiser = min_count_page_advertiser
        @max_count_page_advertiser = max_count_page_advertiser
        @min_duration_page_advertiser = min_duration_page_advertiser
        @max_duration_page_advertiser = max_duration_page_advertiser
        @percent_local_page_advertiser = percent_local_page_advertiser
        @duration_referral = duration_referral
        @min_count_page_organic = min_count_page_organic
        @max_count_page_organic = max_count_page_organic
        @min_duration_page_organic = min_duration_page_organic
        @max_duration_page_organic = max_duration_page_organic
        @min_duration = min_duration
        @max_duration = max_duration
        @fqdn_advertisings = fqdn_advertisings
      end

      def send_to_calendar
        data = {"website_label" => @website_label,
                "objective_id" => @objective_id,
                "policy_id" => @policy_id,
                "website_id" => @website_id,
                "policy_type" => @policy_type,
                "count_weeks" => @count_weeks,
                "execution_mode" => @execution_mode,
                "count_visits" => @count_visits,
                "url_root" => @url_root,
                "direct_medium_percent" => @direct_medium_percent,
                "organic_medium_percent" => @organic_medium_percent,
                "referral_medium_percent" => @referral_medium_percent,
                "visit_bounce_rate" => @visit_bounce_rate,
                "page_views_per_visit" => @page_views_per_visit,
                "avg_time_on_site" => @avg_time_on_site,
                "min_durations" => @min_durations,
                "min_pages" => @min_pages,
                "hourly_distribution" => @hourly_distribution,
                "advertisers" => @advertisers,
                "advertising_percent" => @advertising_percent,
                "periodicity" => @periodicity,
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
                "fqdn_advertisings" => @fqdn_advertisings
        }
        @query = {"cmd" => "save"}
        @query.merge!({"object" => "Objective"})
        @query.merge!({"data" => data})


        response = RestClient.post "http://localhost:#{$calendar_server_port}/objectives/objective/", data.to_json, :content_type => :json, :accept => :json
        if response.code != 200
          raise "Objective <#{info.join(",")}> not save => #{response.code}"
        end


      end

      def send_to_statupweb
        # informe statupweb du nouvel etat d'un task
        # en cas d'erreur on ne leve pas une exception car cela ne met en peril le comportement fonctionnel de derouelement de lexecution de la policy.
        # on peut identifier avec event_id la task d�j� p�sente dans statupweb pour faire un update plutot que d'jouter une nouvelle task
        # avoir si le besoin se fait sentir en terme de pr�sention IHM (plus lisible)
        begin

          obj = {:count_visits => @count_visits,
                 :visit_bounce_rate => @visit_bounce_rate,
                 :avg_time_on_site => @avg_time_on_site,
                 :page_views_per_visit => @page_views_per_visit,
                 :hourly_distribution => @hourly_distribution,
                 :policy_id => @policy_id,
                 :policy_type => @policy_type,
                 :day => IceCube::Schedule.load(@periodicity).start_time.to_date
          }
          response = RestClient.post "http://#{$statupweb_server_ip}:#{$statupweb_server_port}/objectives/",
                                     JSON.generate(obj),
                                     :content_type => :json,
                                     :accept => :json
          raise response.content if response.code != 201

        rescue Exception => e
          raise "#{$statupweb_server_ip}:#{$statupweb_server_port} => #{e.message}"
        else

        end
      end

      def to_s(*a)
        "website_label: #{@website_label}\n\r" \
            "objective_id: #{@objective_id}\n\r" \
            "policy_id: #{@policy_id}\n\r" \
            "website_id: #{@website_id}\n\r" \
            "policy_type: #{@policy_type}\n\r" \
            "count_weeks: #{@count_weeks}\n\r" \
            "count_visits: #{@count_visits}\n\r" \
            "url_root: #{@url_root}\n\r" \
            "direct_medium_percent: #{@direct_medium_percent}\n\r" \
            "organic_medium_percent: #{@organic_medium_percent}\n\r" \
            "referral_medium_percent: #{@referral_medium_percent}\n\r" \
            "visit_bounce_rate: #{@visit_bounce_rate}\n\r" \
            "page_views_per_visit: #{@page_views_per_visit}\n\r" \
            "avg_time_on_site: #{@avg_time_on_site}\n\r" \
            "min_durations: #{@min_durations}\n\r" \
            "min_pages: #{@min_pages}\n\r" \
            "hourly_distribution: #{@hourly_distribution}\n\r" \
            "advertisers: #{@advertisers}\n\r" \
            "advertising_percent: #{@advertising_percent}\n\r" \
            "periodicity: #{@periodicity}\n\r" \
            "min_count_page_advertiser: #{@min_count_page_advertiser}\n\r" \
            "max_count_page_advertiser: #{@max_count_page_advertiser}\n\r" \
            "min_duration_page_advertiser: #{@min_duration_page_advertiser}\n\r" \
            "max_duration_page_advertiser: #{@max_duration_page_advertiser}\n\r" \
            "percent_local_page_advertiser: #{@percent_local_page_advertiser}\n\r" \
            "duration_referral: #{@duration_referral}\n\r" \
            "min_count_page_organic: #{@min_count_page_organic}\n\r" \
            "max_count_page_organic: #{@max_count_page_organic}\n\r" \
            "min_duration_page_organic: #{@min_duration_page_organic}\n\r" \
            "max_duration_page_organic: #{@max_duration_page_organic}\n\r" \
            "min_duration: #{@min_duration}\n\r" \
            "max_duration: #{@max_duration}\`n\r" \
            "fqdn_advertisings: #{@fqdn_advertisings}"
      end

      private
      def translate_to_count_visits_target(distribution, count_visits_of_day_target)
        count_visits_of_day_origin = 0
        count_visits_of_day = distribution.split(SEPARATOR4)
        count_visits_of_day.each { |count_visit_per_hour| count_visits_of_day_origin += count_visit_per_hour.to_i }
        count_visits_of_day.map! { |count_visit_per_hour| count_visit_per_hour.to_i * count_visits_of_day_target / count_visits_of_day_origin }
        count_visits_of_day_inter = 0
        count_visits_of_day.each { |count_visit_per_hour| count_visits_of_day_inter += count_visit_per_hour.to_i }
        (count_visits_of_day_target - count_visits_of_day_inter).times { count_visits_of_day[rand(count_visits_of_day.size-1)] += 1 }
        count_visits_of_day.join(SEPARATOR4)
      end
    end

  end
end