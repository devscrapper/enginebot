#!/usr/bin/env ruby -w
# encoding: UTF-8
require 'socket'
require "ruby-progressbar"
require_relative "traffic_source"

module Tasking
  INPUT = File.dirname(__FILE__) + "/../../../input"


  SEPARATOR1="%SEP%"

  SEPARATOR3="|"
  SEPARATOR4=","


  class Inputs
#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------
    attr :label,
         :date_building,
         :policy_type

    def initialize(label, date_building, policy_type)
      @label = label
      @date_building = date_building
      @policy_type = policy_type
      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
    end

    def Building_landing_pages(medium)
      @logger.an_event.debug "Building landing pages #{medium} for <#{@policy_type}> <#{@label}> <#{@date_building}> is starting"
      begin

        case medium
          when :direct
            convert_to_landing_page("scraping-website", medium) { |p| Traffic_source_direct.new(p) }

          when :referral
            convert_to_landing_page("scraping-traffic-source-referral", medium) { |p| Traffic_source_referral.new(p) }

          when :organic
            convert_to_landing_page("scraping-traffic-source-organic", medium) { |p| Traffic_source_organic.new(p) }

        end


      rescue Exception => e
        @logger.an_event.error ("Building landing pages #{medium} for <#{@policy_type}> <#{@label}> is over #{e.message}")
      else
        @logger.an_event.debug("Building landing pages #{medium} for <#{@policy_type}> <#{@label}> is over")
      end

    end


    private


    def convert_to_landing_page(traffic_source_type_flow, medium, &bloc)

      landing_page_type_flow = "landing-pages-#{medium.to_s}"
      traffic_source_file = Flow.last(INPUT, {:type_flow => traffic_source_type_flow,
                                           :label => @label,
                                           :policy => @policy_type}).last #input
      @logger.an_event.debug "traffic source type flow : #{traffic_source_file.basename}"
      raise IOError, "input flow <#{traffic_source_file.basename}> is missing" unless traffic_source_file.exist? #input

      landing_pages_file = Flow.new(TMP, landing_page_type_flow, @policy_type, @label, @date_building) #output

      total = 0
      traffic_source_file.volumes.each { |volume| total += volume.count_lines(EOFLINE)}

      pob = ProgressBar.create(:title => title("Building landing #{medium.to_s}"), :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => total, :format => '%t, %c/%C, %a|%w|')
      traffic_source_file.volumes.each { |volume|
        # @logger.an_event.info "Loading vol <#{volume.vol}> of #{traffic_source_file.basename} input file"
#        pob = ProgressBar.create(:title => "Loading vol <#{volume.vol}> of #{traffic_source_file.basename} input file", :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => volume.count_lines(EOFLINE), :format => '%t, %c/%C, %a|%w|')
        volume.foreach(EOFLINE) { |p|
          source_page = yield(p)
          landing_pages_file.write(source_page.to_s)
          pob.increment
        }
      }

      landing_pages_file.close
      landing_pages_file.archive_previous
    end
    private
    def title(action, policy = @policy_type, label = @label, date = @date_building)
      [action, policy, label, date].join(" | ")
    end
  end

end


