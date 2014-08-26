#!/usr/bin/env ruby -w
# encoding: UTF-8
require_relative '../../lib/logging'
require_relative '../flow'
require_relative 'visit'
require_relative 'page'
require 'ruby-progressbar'
require 'pathname'

module Building
  class Reporting
    TMP = Pathname.new(File.dirname(__FILE__) + "/../../tmp").realpath
    #statistics
    attr_reader :label,
                :date_building,
                :hours, #repartition horaire du nombre de visit pour la journée courante
                :return_visitor_count,
                :device_platforms, # nombre de visite par (browser, browser_version, os, os_version, flash_version, java_enabled, screen_colors, screen_resolution)
                :direct_count,
                :referral_count, # nombre de visite par medium (referral)
                :organic_count,
                :visit_count,
                :visit_bounce_count,
                :page_views_per_visit_count,
                :time_on_site_count,
                :min_durations,
                :min_pages
    #objectives
    attr_reader :hours_obj,
                :return_visitor_rate_obj,
                :device_platforms_obj,
                :direct_medium_percent_obj,
                :organic_medium_percent_obj,
                :referral_medium_percent_obj,
                :visit_count_obj,
                :visit_bounce_rate_obj,
                :page_views_per_visit_obj,
                :avg_time_on_site_obj,
                :min_durations_obj,
                :min_pages_obj

    def initialize (label, date_building)
      begin
        data = YAML::load(Flow.new(TMP, "reporting-visits", label, date_building, nil, ".yml").read)
      rescue Exception => e
        @label = label
        @date_building = date_building
        #statitics
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
        #objectives
        @hours_obj = Array.new(24, 0)
        @return_visitor_rate_obj = 0
        @direct_medium_percent_obj = 0
        @organic_medium_percent_obj = 0
        @referral_medium_percent_obj = 0
        @device_platforms_obj = {}
        @visit_count_obj = 0
        @visit_bounce_rate_obj = 0
        @page_views_per_visit_obj = 0
        @avg_time_on_site_obj = 0
        @min_durations_obj = 0
        @min_pages_obj
      else
        @label = label
        @date_building = date_building
        #statistics
        @hours = data.hours
        @return_visitor_count = data.return_visitor_count
        @direct_count = data.direct_count
        @referral_count = data.referral_count
        @organic_count = data.organic_count
        @device_platforms = data.device_platforms
        @visit_count = data.visit_count
        @visit_bounce_count = data.visit_bounce_count
        @page_views_per_visit_count = data.page_views_per_visit_count
        @time_on_site_count = data.time_on_site_count
        @min_durations = data.min_durations
        @min_pages = data.min_pages
        #objectives
        @hours_obj = data.hours_obj
        @return_visitor_rate_obj = data.return_visitor_rate_obj
        @direct_medium_percent_obj = data.direct_medium_percent_obj
        @organic_medium_percent_obj = data.organic_medium_percent_obj
        @referral_medium_percent_obj = data.referral_medium_percent_obj
        @device_platforms_obj = data.device_platforms_obj
        @visit_count_obj = data.visit_count_obj
        @visit_bounce_rate_obj = data.visit_bounce_rate_obj
        @page_views_per_visit_obj = data.page_views_per_visit_obj
        @avg_time_on_site_obj = data.avg_time_on_site_obj
        @min_durations_obj = data.min_durations_obj
        @min_pages_obj = data.min_pages_obj
      ensure
        p self
      end
    end

    def device_platform_obj(device_platform)
      @device_platforms_obj[device_platform.browser] = {} if @device_platforms_obj[device_platform.browser].nil?
      @device_platforms_obj[device_platform.browser][device_platform.browser_version] = {} if @device_platforms_obj[device_platform.browser][device_platform.browser_version].nil?
      @device_platforms_obj[device_platform.browser][device_platform.browser_version][device_platform.os] = {} if @device_platforms_obj[device_platform.browser][device_platform.browser_version][device_platform.os].nil?
      @device_platforms_obj[device_platform.browser][device_platform.browser_version][device_platform.os][device_platform.os_version] = {} if @device_platforms_obj[device_platform.browser][device_platform.browser_version][device_platform.os][device_platform.os_version].nil?
      @device_platforms_obj[device_platform.browser][device_platform.browser_version][device_platform.os][device_platform.os_version][device_platform.flash_version] = {} if @device_platforms_obj[device_platform.browser][device_platform.browser_version][device_platform.os][device_platform.os_version][device_platform.flash_version].nil?
      @device_platforms_obj[device_platform.browser][device_platform.browser_version][device_platform.os][device_platform.os_version][device_platform.flash_version][device_platform.java_enabled] = {} if @device_platforms_obj[device_platform.browser][device_platform.browser_version][device_platform.os][device_platform.os_version][device_platform.flash_version][device_platform.java_enabled].nil?
      @device_platforms_obj[device_platform.browser][device_platform.browser_version][device_platform.os][device_platform.os_version][device_platform.flash_version][device_platform.java_enabled][device_platform.screen_colors] = {} if @device_platforms_obj[device_platform.browser][device_platform.browser_version][device_platform.os][device_platform.os_version][device_platform.flash_version][device_platform.java_enabled][device_platform.screen_colors].nil?
      @device_platforms_obj[device_platform.browser][device_platform.browser_version][device_platform.os][device_platform.os_version][device_platform.flash_version][device_platform.java_enabled][device_platform.screen_colors][device_platform.screen_resolution] = 0 if @device_platforms_obj[device_platform.browser][device_platform.browser_version][device_platform.os][device_platform.os_version][device_platform.flash_version][device_platform.java_enabled][device_platform.screen_colors][device_platform.screen_resolution].nil?
      @device_platforms_obj[device_platform.browser][device_platform.browser_version][device_platform.os][device_platform.os_version][device_platform.flash_version][device_platform.java_enabled][device_platform.screen_colors][device_platform.screen_resolution] += 1

    end

    def landing_pages_obj(direct_medium_percent, organic_medium_percent, referral_medium_percent)
      @direct_medium_percent_obj = direct_medium_percent
      @organic_medium_percent_obj = organic_medium_percent
      @referral_medium_percent_obj = referral_medium_percent
    end

    def planification_obj(hourly_distribution)
      @hours_obj = hourly_distribution.split(Visits::SEPARATOR2).map { |h| h.to_i }
    end

    def return_visitor_obj(return_visitor_rate)
      @return_visitor_rate_obj = return_visitor_rate
    end

    def visit_obj(count_visit, visit_bounce_rate, page_views_per_visit, avg_time_on_site, min_durations, min_pages)
      @visit_count_obj = count_visit
      @visit_bounce_rate_obj = visit_bounce_rate
      @page_views_per_visit_obj = page_views_per_visit
      @avg_time_on_site_obj = avg_time_on_site
      @min_durations_obj = min_durations
      @min_pages_obj = min_pages
    end

    def visit(visit)
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

    def to_html
      html =<<-_end_of_html_
<HTML><HEAD></HEAD><BODY><table><tr><th>Dimension</th><th>Objective</th><th>Statistic</th></tr>
#{dimension("Visit count", @visit_count_obj, @visit_count)}
      #{dimension("Visit bounce rate", @visit_bounce_rate_obj, (@visit_bounce_count * 100/ @visit_count).round(0))}
      #{dimension("Return visitor rate", @return_visitor_rate_obj, (@return_visitor_count * 100/ @visit_count).round(0))}
      #{dimension("Direct medium percent", @direct_medium_percent_obj, (@direct_count * 100/ @visit_count).round(0))}
      #{dimension("Referral medium percent", @referral_medium_percent_obj, (@referral_count * 100/ @visit_count).round(0))}
      #{dimension("organic medium percent", @organic_medium_percent_obj, (@organic_count * 100/ @visit_count).round(0))}
      #{dimension("page views per visit count", @page_views_per_visit_obj, (@page_views_per_visit_count * 100/ @visit_count).round(0))}
      #{dimension("avg time on site", @avg_time_on_site_obj, (@time_on_site_count * 100/ @visit_count).round(0))}
      #{dimension("Min duration", @min_durations_obj, @min_durations)}
      #{dimension("Min page", @min_pages, @min_pages_obj)}
      #{24.times.collect { |h| dimension("#{h}:00-#{h+1}:00", @hours_obj[h], @hours[h]) }.join}
</table><BODY></HTML>
      _end_of_html_
    end

    private
    def device_platforms_display
    statistic = [keys(@device_platforms), value(@device_platforms)]
    objective = [keys(@device_platforms_obj), value(@device_platforms_obj)]
    objective.map{|k,v| [dimension(k,v,statistic[k].nil? ? 0 : statistic[k])].join}
    end

    def dimension(title, objective, statistic)
      <<-_end_of_html_
    <tr><td>#{title}</td><td>#{objective}</td><td>#{statistic}</td></tr>
      _end_of_html_
    end

    def keys(h)
      [h.map { |k, v| [k, v.is_a?(Hash) ? ",#{keys(v)}" : ""] },].join
    end

    def value(h)
      [h.map { |k, v| [v.is_a?(Hash) ? value(v) : v] },].join.to_i
    end
  end
end