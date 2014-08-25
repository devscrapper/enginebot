#!/usr/bin/env ruby -w
# encoding: UTF-8
require_relative '../../lib/logging'
require_relative 'visit'
require_relative 'page'
require 'ruby-progressbar'
require 'pathname'

module Building
  class Reporting
    TMP = Pathname.new(File.dirname(__FILE__) + "/../../tmp").realpath

    attr_reader :label,
                :date_building,
                :hours, #repartition horaire du nombre de visit pour la journée courante
                :return_visitor_count,
                :device_platforms, # nombre de visite par (browser, browser_version, os, os_version, flash_version, java_enabled, screen_colors, screen_resolution)
                :referral_count, # nombre de visite par medium (referral)
                :direct_count,
                :organic_count,
                :visit_count,
                :visit_bounce_count,
                :page_views_per_visit_count,
                :time_on_site_count,
                :min_durations,
                :min_pages


    def initialize (label, date_building)
      @label = label
      @date_building = date_building
      @hours = Array.new(24, 0)
      @return_visitor_count = 0
      @device_platforms = {}
      @referral_count = 0
      @direct_count = 0
      @organic_count = 0
      @visit_count = 0
      @visit_bounce_count = 0
      @page_views_per_visit_count = 0
      @time_on_site_count = 0
      @min_durations = 9999
      @min_pages = 9999
    end

    def <<(visit)
      @hours[visit.start_date_time.hour] += 1
      @return_visitor_count += visit.return_visitor == true ? 1 : 0


      @device_platforms[visit.browser] = {} if @device_platforms[visit.browser].nil?
      @device_platforms[visit.browser][visit.browser_version] = {} if @device_platforms[visit.browser][visit.browser_version].nil?
      @device_platforms[visit.browser][visit.browser_version][visit.operating_system] = {} if @device_platforms[visit.browser][visit.browser_version][visit.operating_system].nil?
      @device_platforms[visit.browser][visit.browser_version][visit.operating_system][visit.operating_system_version] = {} if @device_platforms[visit.browser][visit.browser_version][visit.operating_system][visit.operating_system_version].nil?
      @device_platforms[visit.browser][visit.browser_version][visit.operating_system][visit.operating_system_version][visit.flash_version] = {} if @device_platforms[visit.browser][visit.browser_version][visit.operating_system][visit.operating_system_version][visit.flash_version].nil?
      @device_platforms[visit.browser][visit.browser_version][visit.operating_system][visit.operating_system_version][visit.flash_version][visit.java_enabled] = {} if @device_platforms[visit.browser][visit.browser_version][visit.operating_system][visit.operating_system_version][visit.flash_version][visit.java_enabled].nil?
      @device_platforms[visit.browser][visit.browser_version][visit.operating_system][visit.operating_system_version][visit.flash_version][visit.java_enabled][visit.screens_colors] = {} if @device_platforms[visit.browser][visit.browser_version][visit.operating_system][visit.operating_system_version][visit.flash_version][visit.java_enabled][visit.screens_colors].nil?
      @device_platforms[visit.browser][visit.browser_version][visit.operating_system][visit.operating_system_version][visit.flash_version][visit.java_enabled][visit.screens_colors][visit.screen_resolution] = 0 if @device_platforms[visit.browser][visit.browser_version][visit.operating_system][visit.operating_system_version][visit.flash_version][visit.java_enabled][visit.screens_colors][visit.screen_resolution].nil?


      @device_platforms[visit.browser][visit.browser_version][visit.operating_system][visit.operating_system_version][visit.flash_version][visit.java_enabled][visit.screens_colors][visit.screen_resolution] += 1

      case visit.medium
        when "(none)"
          @direct_count += 1
        when "referral"
          @referral_count +=1
        when "organic"
          @organic_count += 1
      end
      @visit_count += 1
      @visit_bounce_count += 1 if visit.pages.size == 1
      @page_views_per_visit_count += visit.pages.size

      visit.pages.each { |page|
        @time_on_site_count += page.delay_from_start.to_i
        @min_durations = page.delay_from_start.to_i if @min_durations > page.delay_from_start.to_i
      }
      @min_pages = visit.pages.size if @min_pages > visit.pages.size
    end


    def to_file
      reporting_file = Flow.new(TMP, "reporting-visits", @label, @date_building, nil, ".yml") #output
      reporting_file.archive_previous
      reporting_file.write(self.to_yaml)
      reporting_file.close
    end

    def to_mail
       # TO_DO : meo de la fonction d'nevoie de mail du reporting.
    end

  end
end