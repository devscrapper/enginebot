#!/usr/bin/env ruby -w
# encoding: UTF-8
require_relative '../../lib/logging'
require_relative 'objective'
require_relative '../../model/flow'
#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------
require 'ruby-progressbar'
module Building
#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------
  TMP = File.dirname(__FILE__) + "/../../tmp"
  SEPARATOR2 =";"
  EOFLINE2 ="\n"
  PROGRESS_BAR_SIZE = 180
  class Objectives
    class ObjectivesArgumentError < ArgumentError
    end

    def initialize
      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
    end

#--------------------------------------------------------------------------------------------------------------
# Publishing
#--------------------------------------------------------------------------------------------------------------
#
# --------------------------------------------------------------------------------------------------------------

    def Building_objectives(label, date,
        change_count_visits_percent,
        change_bounce_visits_percent,
        direct_medium_percent,
        organic_medium_percent,
        referral_medium_percent,
        advertising_percent,
        advertisers,
        policy_id,
        website_id,
        url_root)

      @logger.an_event.info "Building objectives for <#{label}> is starting"
      @logger.an_event.debug "change_count_visits_percent #{change_count_visits_percent}"
      @logger.an_event.debug "change_bounce_visits_percent #{change_bounce_visits_percent}"
      @logger.an_event.debug "direct_medium_percent #{direct_medium_percent}"
      @logger.an_event.debug "organic_medium_percent #{organic_medium_percent}"
      @logger.an_event.debug "referral_medium_percent #{referral_medium_percent}"
      @logger.an_event.debug "advertising_percent #{advertising_percent}"
      @logger.an_event.debug "advertisers #{advertisers}"
      @logger.an_event.debug "policy_id #{policy_id}"
      @logger.an_event.debug "website_id #{website_id}"
      @logger.an_event.debug "url_root #{url_root}"

      begin
        hourly_daily_distribution = []
        hourly_daily_distribution_file = Flow.new(TMP, "hourly-daily-distribution", label, date).last #input
        raise IOError, "tmp flow hourly-daily-distribution <#{label}> for <#{date}> is missing" if hourly_daily_distribution_file.nil?
        behaviour_file = Flow.new(TMP, "behaviour", label, date).last
        raise IOError, "tmp flow behaviour <#{label}> for <#{date}> is missing" if behaviour_file.nil?

        behaviour_file_size = behaviour_file.count_lines(EOFLINE2)
        hourly_daily_distribution_file_size = hourly_daily_distribution_file.count_lines(EOFLINE2)
        raise "<#{behaviour_file.basename}> and <#{hourly_daily_distribution_file.basename}> have not the same number of days <#{behaviour_file_size}> and <#{hourly_daily_distribution_file_size}>" if behaviour_file_size != hourly_daily_distribution_file_size
        hourly_daily_distribution = hourly_daily_distribution_file.load_to_array(EOFLINE2)
        behaviour = behaviour_file.load_to_array(EOFLINE2)

        p = ProgressBar.create(:title => "Building objectives", :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => behaviour_file_size, :format => '%t, %c/%C, %a|%w|')
        day = next_monday(date)

        behaviour_file_size.times { |line|
          splitted_behaviour = behaviour[line].strip.split(SEPARATOR2)
          splitted_hourly_daily_distribution = hourly_daily_distribution[line].strip.split(SEPARATOR2)
          obj = Objective.new(label, day,
                              (splitted_behaviour[5].to_i * (change_count_visits_percent.to_f / 100)).to_i,
                              (splitted_behaviour[2].to_f * (change_bounce_visits_percent.to_f / 100)).round(2),
                              splitted_behaviour[1].to_f.round(2),
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
                              policy_id,
                              website_id,
                              url_root)

          @logger.an_event.debug obj

          # TODO mise en commentaire pour supprimer les messages de log qd statupbweb n'est pas demarré : aucune interet à ce jour
          # TODO tant que statupweb n a pas été revisé
          # TODO sortir cet envoie de l'exception cannot building objective car ce n'est pas revelateur d'un bug de creation de objective
          # TODO mais un prb de reporting
=begin
        begin
          obj.send_to_db($statupweb_server_ip, $statupweb_server_port)
          @logger.an_event.info "send objective for <#{label}> at date <#{day}> to statupweb"
        rescue Exception => e
          @logger.an_event.debug e
          @logger.an_event.warn "cannot send objective <#{label}> at date <#{day}> to statupweb(#{$statupweb_server_ip}:#{$statupweb_server_port})"
        end
=end
          begin
            obj.send_to_calendar("localhost", $calendar_server_port)
            @logger.an_event.info "send objective for <#{label}> at date <#{day}> to calendar enginebot (localhost:#{$calendar_server_port})"
            obj.send_to_calendar($scraperbot_calendar_server_ip, $scraperbot_calendar_server_port)
            @logger.an_event.info "send objective for <#{label}> at date <#{day}> to calendar scraperbot (#{$scraperbot_calendar_server_ip}:#{$scraperbot_calendar_server_port})"
          rescue Exception => e
            @logger.an_event.debug e
            raise IOError, "cannot send objective <#{label}> at date <#{day}> to calendar"
          end
          p.increment
          day = day.next_day(1)
        }
      rescue Exception => e
        @logger.an_event.debug e
        @logger.an_event.error "cannot building objectives for <#{label}>"
      end
      @logger.an_event.info "Building objectives for <#{label}> is over"
    end

    #private
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