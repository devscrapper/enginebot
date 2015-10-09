#!/usr/bin/env ruby -w
# encoding: UTF-8

require_relative '../../flow'
require_relative '../../../lib/mail_sender'


module Tasking
  class Reporting


    #statistics
    attr_reader :label,
                :policy_type,
                :date_building,
                :hours, #repartition horaire du nombre de visit pour la journée courante
                :device_platforms, # nombre de visite par (browser, browser_version, os, os_version, screen_resolution)
                :direct_count,
                :referral_count, # nombre de visite par medium (referral)
                :organic_count,
                :visit_count,
                :visit_bounce_count,
                :page_views_per_visit_count,
                :time_on_site_count,
                :min_durations,
                :min_pages,
                :advertising_count, # nombre de visits qui ont un advert
                :advertisers
    #objectives
    attr_reader :hours_obj,
                :device_platforms_obj, # nombre de visite par (browser, browser_version, os, os_version, screen_resolution)
                :direct_medium_percent_obj,
                :organic_medium_percent_obj,
                :referral_medium_percent_obj,
                :visit_count_obj,
                :visit_bounce_rate_obj,
                :page_views_per_visit_obj,
                :avg_time_on_site_obj,
                :min_durations_obj,
                :min_pages_obj,
                :advertisers_obj,
                :advertising_percent_obj

    def initialize (label, date_building,policy_type)
      begin
        data = YAML::load(Flow.new(TMP, "reporting-visits", policy_type, label, date_building, nil, ".yml").read)
      rescue Exception => e
        @label = label
        @date_building = date_building
        @policy_type = policy_type
        #statitics
        @hours = Array.new(24, 0)
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
        @advertising_count = 0
        @advertisers = []
        #objectives
        @hours_obj = Array.new(24, 0)
        @direct_medium_percent_obj = 0
        @organic_medium_percent_obj = 0
        @referral_medium_percent_obj = 0
        @device_platforms_obj = {}
        @visit_count_obj = 0
        @visit_bounce_rate_obj = 0
        @page_views_per_visit_obj = 0
        @avg_time_on_site_obj = 0
        @min_durations_obj = 0
        @min_pages_obj = 0
        @advertisers_obj = []
        @advertising_percent_obj = 0
      else
        @label = label
        @date_building = date_building
        @policy_type = policy_type
        #statistics
        @hours = data.hours
        @direct_count = data.direct_count
        @referral_count = data.referral_count
        @organic_count = data.organic_count
        @device_platforms = data.device_platforms
        @advertisers = data.advertisers
        @advertising_count = data.advertising_count
        @visit_count = data.visit_count
        @visit_bounce_count = data.visit_bounce_count
        @page_views_per_visit_count = data.page_views_per_visit_count
        @time_on_site_count = data.time_on_site_count
        @min_durations = data.min_durations
        @min_pages = data.min_pages
        #objectives
        @hours_obj = data.hours_obj
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
        @advertisers_obj = data.advertisers
        @advertising_percent_obj = data.advertising_percent_obj
      ensure

      end
    end

    def archive
      #archive les anciens reporting et laisse le dernier du site
      Flow.new(TMP, "reporting-visits", @policy_type, @label, @date_building, nil, ".yml").archive_previous
    end

    def device_platform_obj(device_platform, count_visits)
      @device_platforms_obj[device_platform.os] = {} if @device_platforms_obj[device_platform.os].nil?
      @device_platforms_obj[device_platform.os][device_platform.os_version] = {} if @device_platforms_obj[device_platform.os][device_platform.os_version].nil?
      @device_platforms_obj[device_platform.os][device_platform.os_version][device_platform.browser] = {} if @device_platforms_obj[device_platform.os][device_platform.os_version][device_platform.browser].nil?
      @device_platforms_obj[device_platform.os][device_platform.os_version][device_platform.browser][device_platform.browser_version] = {} if @device_platforms_obj[device_platform.os][device_platform.os_version][device_platform.browser][device_platform.browser_version].nil?
      @device_platforms_obj[device_platform.os][device_platform.os_version][device_platform.browser][device_platform.browser_version][device_platform.screen_resolution] = 0 if  @device_platforms_obj[device_platform.os][device_platform.os_version][device_platform.browser][device_platform.browser_version][device_platform.screen_resolution].nil?
      @device_platforms_obj[device_platform.os][device_platform.os_version][device_platform.browser][device_platform.browser_version][device_platform.screen_resolution] += (device_platform.count_visits * count_visits / 100).to_i

    end

    def landing_pages_obj(direct_medium_percent, organic_medium_percent, referral_medium_percent)
      @direct_medium_percent_obj = direct_medium_percent
      @organic_medium_percent_obj = organic_medium_percent
      @referral_medium_percent_obj = referral_medium_percent
    end

    def planification_obj(hourly_distribution)
      @hours_obj = hourly_distribution.split(Visits::SEPARATOR2) #.map { |h| h.to_i }
    end


    def to_file (title)
      begin
        reporting_file = Flow.new(TMP, "reporting-visits", @policy_type, @label, @date_building, nil, ".yml") #output
        reporting_file.write(self.to_yaml)
        reporting_file.close
      rescue Exception => e
        $stderr << "Reporting #{title} not save to file #{reporting_file.basename} : #{e.message}" << "\n"
      else
        $stdout << "Reporting #{title} save to file #{reporting_file.basename}" << "\n"
      end
    end

    def to_html
      html =<<-_end_of_html_
<HTML><HEAD><style>.dimension {text-align:right;} .value {text-align:center;} </style></HEAD><BODY><table><tr><th class='dimension'>Dimension</th><th class='value'>Objective</th><th class='value'>Statistic</th></tr>
#{dimension_html("Visit count", @visit_count_obj, @visit_count)}
      #{dimension_html("Visit bounce rate", @visit_bounce_rate_obj, (@visit_bounce_count * 100/ @visit_count).round(0))}
      #{dimension_html("Direct medium percent", @direct_medium_percent_obj, (@direct_count * 100/ @visit_count).round(0))}
      #{dimension_html("Referral medium percent", @referral_medium_percent_obj, (@referral_count * 100/ @visit_count).round(0))}
      #{dimension_html("organic medium percent", @organic_medium_percent_obj, (@organic_count * 100/ @visit_count).round(0))}
      #{dimension_html("page views per visit count", @page_views_per_visit_obj, (@page_views_per_visit_count * 100/ @visit_count).round(0))}
      #{dimension_html("avg time on site", @avg_time_on_site_obj, (@time_on_site_count * 100/ @visit_count).round(0))}
      #{dimension_html("Min duration", @min_durations_obj, @min_durations)}
      #{dimension_html("Min page", @min_pages, @min_pages_obj)}
      #{dimension_html("Advertising percent", @advertising_percent_obj, (@advertising_count * 100/ @visit_count).round(0))}
      #{dimension_html("Advertisers", @advertisers_obj, @advertisers)}
      #{24.times.collect { |h| dimension_html("#{h}:00-#{h+1}:00", @hours_obj[h], @hours[h]) }.join}
      #{device_platforms_display_html}
</table><BODY></HTML>
      _end_of_html_
      html.gsub("\n", "")
    end

    def to_mail
      begin
        MailSender.new("visits@building.fr", "olinouane@gmail.com", "reporting", to_html).send_html
      rescue Exception => e
        $stderr << "reporting mail not send to olinouane@gmail.com : #{e.message}" << "\n"
      else
        $stdout << "reporting mail send to olinouane@gmail.com" << "\n"
      end
    end

    def to_s
      begin
    t =   <<-_end_of_string_
#{dimension_s("Visit count", @visit_count_obj, @visit_count)}
      #{dimension_s("Visit bounce rate", @visit_bounce_rate_obj, (@visit_bounce_count * 100/ @visit_count).round(0))}
      #{dimension_s("Direct medium percent", @direct_medium_percent_obj, (@direct_count * 100/ @visit_count).round(0))}
      #{dimension_s("Referral medium percent", @referral_medium_percent_obj, (@referral_count * 100/ @visit_count).round(0))}
      #{dimension_s("organic medium percent", @organic_medium_percent_obj, (@organic_count * 100/ @visit_count).round(0))}
      #{dimension_s("page views per visit count", @page_views_per_visit_obj, (@page_views_per_visit_count * 100/ @visit_count).round(0))}
      #{dimension_s("avg time on site", @avg_time_on_site_obj, (@time_on_site_count * 100/ @visit_count).round(0))}
      #{dimension_s("Min duration", @min_durations_obj, @min_durations)}
      #{dimension_s("Min page", @min_pages, @min_pages_obj)}
      #{dimension_s("Advertising percent", @advertising_percent_obj, (@advertising_count * 100/ @visit_count).round(0))}
      #{dimension_s("Advertisers", @advertisers_obj, @advertisers)}
      #{24.times.collect { |h| dimension_s("#{h}:00-#{h+1}:00", @hours_obj[h], @hours[h]) }.join}
      #{device_platforms_display_s}
      _end_of_string_
      rescue Exception => e
        $stderr << e.message
        $stderr << e.backtrace
      end
       t
    end

    def visit(visit)
      #TODO page views per visit count	!= de l'obj : 2	199
      #TODO avg time on site != de l'obj
      #TODO Min page != de l'obj
      begin
        @hours[visit.start_date_time.hour] += 1

        @device_platforms[visit.operating_system] = {} if @device_platforms[visit.operating_system].nil?
        @device_platforms[visit.operating_system][visit.operating_system_version] = {} if @device_platforms[visit.operating_system][visit.operating_system_version].nil?
        @device_platforms[visit.operating_system][visit.operating_system_version][visit.browser] = {} if @device_platforms[visit.operating_system][visit.operating_system_version][visit.browser].nil?
        @device_platforms[visit.operating_system][visit.operating_system_version][visit.browser][visit.browser_version] = {} if @device_platforms[visit.operating_system][visit.operating_system_version][visit.browser][visit.browser_version].nil?
        @device_platforms[visit.operating_system][visit.operating_system_version][visit.browser][visit.browser_version][visit.screen_resolution] = 0 if  @device_platforms[visit.operating_system][visit.operating_system_version][visit.browser][visit.browser_version][visit.screen_resolution].nil?
        @device_platforms[visit.operating_system][visit.operating_system_version][visit.browser][visit.browser_version][visit.screen_resolution] += 1


        case visit.advert
          when "none"
          else
            @advertising_count += 1
            @advertisers << visit.advert unless @advertisers.include?(visit.advert)
        end

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
          @time_on_site_count += page.delay.to_i
          @min_durations = page.delay.to_i if @min_durations > page.delay.to_i
        }
        @min_pages = visit.pages.size if @min_pages > visit.pages.size
      rescue Exception => e
        $stderr << "calculate statistics visit : #{e.message}" << "\n"
      else
      end
    end

    def advertising_obj(advertising_percent, advertisers)
      @advertising_percent_obj = advertising_percent
      @advertisers_obj = advertisers
    end

    def visit_obj(count_visit, visit_bounce_rate, page_views_per_visit, avg_time_on_site, min_durations, min_pages)
      @visit_count_obj = count_visit
      @visit_bounce_rate_obj = visit_bounce_rate
      @page_views_per_visit_obj = page_views_per_visit
      @avg_time_on_site_obj = avg_time_on_site
      @min_durations_obj = min_durations
      @min_pages_obj = min_pages
    end

    private
    def device_platforms_display_html
      #met en forme les device platforme pour présentation html
      statistic = parcours(@device_platforms)
      objective = parcours(@device_platforms_obj)
      objective.map { |k, v|
        [dimension_html(k, v, statistic[k].nil? ? 0 : statistic[k])].join
      }.join
    end

    def device_platforms_display_s
      #met en forme les device platforme pour présentation html
      statistic = parcours(@device_platforms)
      objective = parcours(@device_platforms_obj)
      objective.map { |k, v|
        [dimension_s(k, v, statistic[k].nil? ? 0 : statistic[k])].join
      }.join
    end

    def dimension_html(title, objective, statistic)
      #mise ne forme html d'une dimension (count_visit, ....) pour présenter dans un tableau.
      <<-_end_of_html_
<tr><td class='dimension'>#{title}</td><td class='value'>#{objective}</td><td class='value'>#{statistic}</td></tr>
      _end_of_html_
    end

    def dimension_s(title, objective, statistic)
      #mise ne forme string d'une dimension (count_visit, ....) pour présenter dans un tableau.
      <<-_end_of_string_
#{title}\t\t\t\t#{objective}\t\t#{statistic}
      _end_of_string_
    end

    def parcours(h, chem=[], chem_arr={})
      #tranforme le hash ayant un profondeur > 1 dont le chemin est les attributs de device_platfoirem (browser, browser_version, os, os_version, screen_resolution) en un hash à une profondeur dont la clé est le chemijn et la valeur le nombre de visite.
      if h.is_a?(Hash)
        i = 0
        h.each_value { |v|
          chem_arr = parcours(v, chem + [h.keys[i]], chem_arr)
          i += 1
        }
        chem_arr
      else
        chem_arr.merge!({[chem.join("-")][0] => h})
      end
    end
  end
end