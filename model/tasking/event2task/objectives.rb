#!/usr/bin/env ruby -w
# encoding: UTF-8
require_relative '../../../lib/logging'
require_relative 'objective'
require_relative '../../flow'
#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------
require 'ruby-progressbar'
module Tasking
#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------

  SEPARATOR2 =";"
  EOFLINE2 ="\n"
  PROGRESS_BAR_SIZE = 180
  TMP = Pathname(File.dirname(__FILE__) + "/../../../tmp").realpath
  class Objectives
    attr :website_label,
         :date_building,
         :policy_id,
         :website_id, :policy_type

    def initialize(website_label, date_building,
                   policy_id,
                   website_id, policy_type)
      @website_label = website_label
      @date_building = date_building
      @policy_id = policy_id
      @policy_type = policy_type
      @website_id = website_id
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
                                    advertisers, url_root)

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
      @logger.an_event.debug "url_root #{url_root}"

      Building_objectives { |day, splitted_behaviour, splitted_hourly_daily_distribution|
        Objective.new(@website_label, day,
                      (splitted_behaviour[5].to_i * (change_count_visits_percent.to_f / 100)).to_i,
                      (splitted_behaviour[2].to_f * (change_bounce_visits_percent.to_f / 100)).round(2),
                      splitted_behaviour[3].to_f.round(2),
                      splitted_behaviour[4].to_f.round(2),
                      10, #min_durations  #TODO à variabiliser un jour ?
                      2, #min_pages #TODO à variabiliser un jour ?
                      direct_medium_percent,
                      referral_medium_percent,
                      organic_medium_percent,
                      advertising_percent,
                      advertisers,
                      splitted_hourly_daily_distribution[1],
                      @policy_id,
                      @website_id,
                      @policy_type,
                      url_root)
      }
    end

    def Building_objectives_rank(count_visits_per_day, url_root)

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
                      10, #min_durations  #TODO à variabiliser un jour ?
                      2, #min_pages #TODO à variabiliser un jour ?
                      0, #direct_medium_percent
                      0, #referral_medium_percent
                      100, #organic_medium_percent
                      0, #advertising_percent
                      "none", #advertisers
                      splitted_hourly_daily_distribution[1], #hour
                      @policy_id,
                      @website_id,
                      @policy_type,
                      url_root)
      }

    end

    private

    def Building_objectives
      begin
        hourly_daily_distribution = []
        hourly_daily_distribution_file = Flow.new(TMP, "hourly-daily-distribution", @policy_type, @website_label, @date_building).last #input
        raise IOError, "tmp flow hourly-daily-distribution <#{@policy_type}> <#{@website_label}>  for <#{@date_building}> is missing" if hourly_daily_distribution_file.nil?

        behaviour_file = Flow.new(TMP, "behaviour", @policy_type, @website_label, @date_building).last
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

            obj.send_to_scraperbot
            @logger.an_event.debug "send objective for <#{@policy_type}> <#{@website_label}> at date <#{day}> to calendar enginebot (localhost:#{$calendar_server_port})"

            obj.send_to_enginebot
            @logger.an_event.debug "send objective for <#{@policy_type}> <#{@website_label}> at date <#{day}> to calendar scraperbot (#{$scraperbot_calendar_server_ip}:#{$scraperbot_calendar_server_port})"

          rescue Exception => e
            raise StandardError, "cannot send objective <#{@policy_type}> <#{@website_label}> at date <#{day}> to calendar => #{e.message}"
          end
          p.increment
          day = day.next_day(1)
        }
      rescue Exception => e
        @logger.an_event.error "Building objectives for <#{@policy_type}> <#{@website_label}> at date <#{day}> is over => #{e.message}"
      else
        @logger.an_event.debug "Building objectives for <#{@policy_type}> <#{@website_label}> at date <#{day}> is over"
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