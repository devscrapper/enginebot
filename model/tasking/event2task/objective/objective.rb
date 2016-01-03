require 'ice_cube'
require 'uuid'
require_relative '../../../communication'

module Tasking
  module Objective
    class Objective
      class ObjectiveException < StandardError
      end
      SEPARATOR4="|"

      attr :website_label,
           :date,
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
           :max_duration

      def initialize(website_label, date,
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
                     policy_id, website_id, policy_type, count_weeks,
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
                     max_duration)
        @objective_id = UUID.generate(:compact)
        @date = date
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
        @periodicity =IceCube::Schedule.new(Time.local(@date.year, @date.month, @date.day),
                                            :end_time => Time.local(@date.year, @date.month, @date.day)).to_yaml
        @hourly_distribution=translate_to_count_visits_target(hourly_distribution, count_visits)
        @policy_id = policy_id
        @policy_type = policy_type
        @website_id = website_id
        @count_weeks = count_weeks
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
      end

      def send_to_calendar
        data = {"website_label" => @website_label,
                "objective_id" => @objective_id,
                "policy_id" => @policy_id,
                "website_id" => @website_id,
                "policy_type" => @policy_type,
                "count_weeks" => @count_weeks,
                "count_visits" => @count_visits,
                "building_date" => @date,
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
                "max_duration" => @max_duration
        }
        @query = {"cmd" => "save"}
        @query.merge!({"object" => "Objective"})
        @query.merge!({"data" => data})


        response = RestClient.post "http://localhost:#{$calendar_server_port}/objects/objective/", data.to_json, :content_type => :json, :accept => :json
        if response.code != 200
          @logger.an_event.error "Objective <#{info.join(",")}> not save => #{response.code}"
          raise "Objective <#{info.join(",")}> not save => #{response.code}"
        end
        #
        # try_count = 3
        # begin
        #
        #   response = Question.new(@query).ask_to("localhost", $calendar_server_port)
        #
        # rescue Exception => e
        #   try_count -= 1
        #   retry if try_count > 0
        #   raise e
        # else
        #
        #   raise response[:error] if response[:state] == :ko
        #   response[:data] if response[:state] == :ok and !response[:data].nil?
        #
        # end

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