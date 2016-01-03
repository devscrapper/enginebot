#!/usr/bin/env ruby -w
# encoding: UTF-8
require_relative '../../../../lib/logging'
require_relative 'objective'
require_relative '../../../flow'
#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------
require 'ruby-progressbar'
module Tasking
  module Objective
#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------

    SEPARATOR2 =";"
    EOFLINE2 ="\n"
    PROGRESS_BAR_SIZE = 100

    TMP = File.expand_path(File.join("..", "..", "..", "..", "..", "tmp"), __FILE__)
    class Objectives
      attr :website_label,
           :date_building,
           :policy_id,
           :website_id, :policy_type, :count_weeks

      def initialize(website_label, date_building,
                     policy_id,
                     website_id, policy_type,
                     count_weeks)
        @website_label = website_label
        @date_building = date_building
        @policy_id = policy_id
        @policy_type = policy_type
        @website_id = website_id
        @count_weeks = count_weeks
        @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
      end

#--------------------------------------------------------------------------------------------------------------
# Publishing
#--------------------------------------------------------------------------------------------------------------
#
# --------------------------------------------------------------------------------------------------------------


      def Building_objectives_traffic(change_count_visits_percent,
                                      change_bounce_visits_percent,
                                      direct_medium_percent,
                                      organic_medium_percent,
                                      referral_medium_percent,
                                      advertising_percent,
                                      advertisers,
                                      url_root,
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
                                      min_duration_website,
                                      min_pages_website
      )

        @logger.an_event.debug "Building objectives for <#{@policy_type}> <#{@website_label}> <#{@date_building}> is starting"
        @logger.an_event.debug "change_count_visits_percent #{change_count_visits_percent}"
        @logger.an_event.debug "change_bounce_visits_percent #{change_bounce_visits_percent}"
        @logger.an_event.debug "direct_medium_percent #{direct_medium_percent}"
        @logger.an_event.debug "organic_medium_percent #{organic_medium_percent}"
        @logger.an_event.debug "referral_medium_percent #{referral_medium_percent}"
        @logger.an_event.debug "advertising_percent #{advertising_percent}"
        @logger.an_event.debug "advertisers #{advertisers}"
        @logger.an_event.debug "policy_id #{@policy_id}"
        @logger.an_event.debug "website_id #{@website_id}"
        @logger.an_event.debug "policy_type #{@policy_type}"
        @logger.an_event.debug "count_weeks #{@count_weeks}"
        @logger.an_event.debug "url_root #{url_root}"
        @logger.an_event.debug "min_count_page_advertiser #{min_count_page_advertiser}"
        @logger.an_event.debug "max_count_page_advertiser #{max_count_page_advertiser}"
        @logger.an_event.debug "min_duration_page_advertiser #{min_duration_page_advertiser}"
        @logger.an_event.debug "max_duration_page_advertiser #{max_duration_page_advertiser}"
        @logger.an_event.debug "percent_local_page_advertiser #{percent_local_page_advertiser}"
        @logger.an_event.debug "duration_referral #{duration_referral}"
        @logger.an_event.debug "min_count_page_organic #{min_count_page_organic}"
        @logger.an_event.debug "max_count_page_organic #{max_count_page_organic}"
        @logger.an_event.debug "min_duration_page_organic #{min_duration_page_organic}"
        @logger.an_event.debug "max_duration_page_organic #{max_duration_page_organic}"
        @logger.an_event.debug "min_duration #{min_duration}"
        @logger.an_event.debug "max_duration #{max_duration}"
        @logger.an_event.debug "min_duration_website #{min_duration_website}"
        @logger.an_event.debug "min_pages_website #{min_pages_website}"

        Building_objectives { |day, splitted_behaviour, splitted_hourly_daily_distribution|
          Objective.new(@website_label, day,
                        (splitted_behaviour[5].to_i * (change_count_visits_percent.to_f / 100)).to_i,
                        (splitted_behaviour[2].to_f * (change_bounce_visits_percent.to_f / 100)).round(2),
                        splitted_behaviour[3].to_f.round(2),
                        splitted_behaviour[4].to_f.round(2),
                        min_duration_website,
                        min_pages_website,
                        direct_medium_percent,
                        referral_medium_percent,
                        organic_medium_percent,
                        advertising_percent,
                        advertisers,
                        url_root,
                        splitted_hourly_daily_distribution[1],
                        @policy_id,
                        @website_id,
                        @policy_type,
                        @count_weeks,
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
        }
      end

      def Building_objectives_rank(count_visits_per_day,
                                   url_root,
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
                                   min_duration_website,
                                   min_pages_website)

        @logger.an_event.debug "Building objectives for <#{@policy_type}> <#{@website_label}> <#{@date_building}> is starting"
        @logger.an_event.debug "count_visits_per_day #{count_visits_per_day}"
        @logger.an_event.debug "policy_id #{@policy_id}"
        @logger.an_event.debug "website_id #{@website_id}"
        @logger.an_event.debug "policy_type #{@policy_type}"
        @logger.an_event.debug "url_root #{url_root}"

        Building_objectives { |day, splitted_behaviour, splitted_hourly_daily_distribution|
          Objective.new(@website_label, day,
                        count_visits_per_day.to_i,
                        0, #visit_bounce_rate
                        splitted_behaviour[3].to_f.round(2), #avg_time_on_site
                        splitted_behaviour[4].to_f.round(2), #page_views_per_visit
                        min_duration_website, #min_durations
                        min_pages_website, #min_pages
                        0, #direct_medium_percent
                        0, #referral_medium_percent
                        100, #organic_medium_percent
                        0, #advertising_percent
                        "none", #advertisers
                        url_root,
                        splitted_hourly_daily_distribution[1], #hour
                        @policy_id,
                        @website_id,
                        @policy_type,
                        @count_weeks,
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
        }

      end

      private

      def Building_objectives
        begin
          hourly_daily_distribution = []
          hourly_daily_distribution_file = Flow.new(TMP, "hourly-daily-distribution", @policy_type, @website_label, @date_building).last #input
          raise IOError, "tmp flow hourly-daily-distribution <#{@policy_type}> <#{@website_label}>  for <#{@date_building}> is missing" if hourly_daily_distribution_file.nil?

          behaviour_file = Flow.last(TMP, {:type_flow => "behaviour",
                                           :policy => @policy_type,
                                           :label => @website_label})
          raise IOError, "tmp flow behaviour <#{@policy_type}> <#{@website_label}> for <#{@date_building}> is missing" if behaviour_file.nil?

          behaviour_file_size = behaviour_file.count_lines(EOFLINE2)
          hourly_daily_distribution_file_size = hourly_daily_distribution_file.count_lines(EOFLINE2)
          raise "<#{behaviour_file.basename}> and <#{hourly_daily_distribution_file.basename}> have not the same number of days <#{behaviour_file_size}> and <#{hourly_daily_distribution_file_size}>" if behaviour_file_size != hourly_daily_distribution_file_size
          hourly_daily_distribution = hourly_daily_distribution_file.load_to_array(EOFLINE2)
          behaviour = behaviour_file.load_to_array(EOFLINE2)

          p = ProgressBar.create(:title => "Building objectives", :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => behaviour_file_size, :format => '%t, %c/%C, %a|%w|')
          day = next_monday(@date_building)

          behaviour_file_size.times { |line|
            begin
              splitted_behaviour = behaviour[line].strip.split(SEPARATOR2)
              splitted_hourly_daily_distribution = hourly_daily_distribution[line].strip.split(SEPARATOR2)
              obj = yield(day, splitted_behaviour, splitted_hourly_daily_distribution)
              @logger.an_event.debug obj

              obj.send_to_calendar


            rescue Exception => e
              raise StandardError, "cannot send objective <#{@policy_type}> <#{@website_label}> at date <#{day}> to calendar => #{e.message}"
            else
              @logger.an_event.debug "send objective for <#{@policy_type}> <#{@website_label}> at date <#{day}> to calendar)"
            end
            p.increment
            day = day.next_day(1)
          }
        rescue Exception => e
          @logger.an_event.error "Building objectives for <#{@policy_type}> <#{@website_label}> at date <#{@date_building}> is over => #{e.message}"
          raise e
        else
          @logger.an_event.debug "Building objectives for <#{@policy_type}> <#{@website_label}> at date <#{@date_building}> is over"
        end

      end

      def next_monday(date)
        today = Date.parse(date) if date.is_a?(String)
        today = date if date.is_a?(Date)
        return today.next_day(1) if today.sunday?
        return today if today.monday?
        return today.next_day(6) if today.tuesday?
        return today.next_day(5) if today.wednesday?
        return today.next_day(4) if today.thursday?
        return today.next_day(3) if today.friday?
        return today.next_day(2) if today.saturday?
      end
    end
  end
end