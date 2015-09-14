require 'ice_cube'
require 'uuid'
require_relative '../../communication'

module Tasking
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
         :hourly_distribution,
         :periodicity,
         :policy_id, :website_id, :policy_type,
         :objective_id,
         :url_root

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
                   hourly_distribution=nil,
                   policy_id, website_id, policy_type, url_root)
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
      @periodicity =IceCube::Schedule.new(Time.local(@date.year, @date.month, @date.day),
                                          :end_time => Time.local(@date.year, @date.month, @date.day)).to_yaml
      @hourly_distribution=translate_to_count_visits_target(hourly_distribution, count_visits)
      @policy_id = policy_id
      @policy_type = policy_type
      @website_id = website_id
      @url_root = url_root
    end

    def send_to_scraperbot
      send_to_calendar({"website_label" => @website_label,
                        "objective_id" => @objective_id,
                        "policy_id" => @policy_id,
                        "policy_type" => @policy_type,
                        "website_id" => @website_id,
                        "count_visits" => @count_visits,
                        "building_date" => @date,
                        "organic_medium_percent" => @organic_medium_percent,
                        "referral_medium_percent" => @referral_medium_percent,
                        "periodicity" => @periodicity,
                        "url_root" => @url_root},
                       $scraperbot_calendar_server_ip, $scraperbot_calendar_server_port)
    end

    def send_to_enginebot
      send_to_calendar({"website_label" => @website_label,
                        "objective_id" => @objective_id,
                        "policy_id" => @policy_id,
                        "website_id" => @website_id,
                        "policy_type" => @policy_type,
                        "count_visits" => @count_visits,
                        "building_date" => @date,
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
                        "hourly_distribution" => @hourly_distribution,
                        "advertising_percent" => @advertising_percent,
                        "periodicity" => @periodicity,
                       },
                       "localhost", $calendar_server_port)
    end




    def send_to_calendar(data, hostname, where_port)
      data = {"cmd" => "save",
              "object" => "Objective",
              "data" => data}
      begin
        Information.new(data).send_to(hostname, where_port)
      rescue Exception => e
        raise ObjectiveException, e.message
        #TODO gérer les rebus quand le calendar server n'est pas joignable
      end
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