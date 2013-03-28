#!/usr/bin/env ruby -w
# encoding: UTF-8
require 'socket'
require "ruby-progressbar"

module Building
  SEPARATOR="%SEP%"
  EOFLINE="%EOFL%"
  SEPARATOR2=";"
  SEPARATOR4="|"
  EOFLINE2 ="\n"

  class Page
    NO_LINK = "*"
    attr :id_uri,
         :hostname,
         :page_path,
         :title,
         :links

    def initialize(page)
      splitted_page = page.split(SEPARATOR2)
      @id_uri = splitted_page[0].to_i
      @hostname = splitted_page[1]
      @page_path = splitted_page[2]
      @title = splitted_page[3]
      @links = splitted_page[4][1..splitted_page[4].size - 2] unless splitted_page[4].nil?
      @links = NO_LINK if splitted_page[4].nil?
    end

    def to_matrix(*a)
      "#{@id_uri}#{SEPARATOR2}#{@links}#{EOFLINE2}"

    end

    def to_page(*a)
      "#{@id_uri}#{SEPARATOR2}#{@hostname}#{SEPARATOR2}#{@page_path}#{SEPARATOR2}#{@title}#{EOFLINE2}"
    end
  end
  class Traffic_source
    NOT_FOUND = 0
    attr :id_uri,
         :hostname,
         :landing_page_path,
         :referral_path,
         :source,
         :medium,
         :keyword


    def initialize(page)
      #TODO remplacement de SEPARATOR par SEPARATOR2 à valider
      splitted_page = page.split(SEPARATOR2)
      @id_uri = ""
      @hostname = splitted_page[0]
      @landing_page_path = splitted_page[1]
      @referral_path = splitted_page[2]
      @source = splitted_page[3]
      @medium = splitted_page[4]
      @keyword = splitted_page[5]
    end

    def to_landing_page(*a)
      "#{@id_uri}#{SEPARATOR2}#{@referral_path}#{SEPARATOR2}#{@source}#{SEPARATOR2}#{@medium}#{SEPARATOR2}#{@keyword}#{EOFLINE2}"
    end

    def set_id_uri(label, date)
      @id_uri = NOT_FOUND
      pages_file = Common.select_file(TMP, "pages", label, date)
      if !pages_file.nil?
        begin
          IO.foreach(pages_file, EOFLINE2, encoding: "BOM|UTF-8:-") { |page|
            splitted_page = page.split(SEPARATOR2)
            if splitted_page[1] == @hostname and splitted_page[2] == @landing_page_path
              @id_uri = splitted_page[0].to_i
              break
            end
          }
        rescue Exception => e
          Logging.send(LOG_FILE, Logger::ERROR, "#{e.message}", __LINE__)
        end
      else
        @id_uri = NOT_FOUND
      end
    end

    def isknown?()
      !(@id_uri == NOT_FOUND)
    end
  end
  class Device_platform
    attr_accessor :count_visits
    attr :browser,
         :browser_version,
         :os,
         :os_version,
         :flash_version,
         :java_enabled,
         :screen_colors,
         :screen_resolution


    def initialize(plugin, resolution)

      @browser = plugin.browser
      @browser_version = plugin.browser_version
      @os = plugin.os
      @os_version = plugin.os_version
      @flash_version = plugin.flash_version
      @java_enabled = plugin.java_enabled
      @screen_colors = resolution.screen_colors
      @screen_resolution = resolution.screen_resolution
      @count_visits = Common.min(plugin.count_visits, resolution.count_visits)

    end

    def to_s(*a)

      "#{@browser}#{SEPARATOR2}#{@browser_version}#{SEPARATOR2}#{@os}#{SEPARATOR2}#{@os_version}#{SEPARATOR2}#{@flash_version}#{SEPARATOR2}#{@java_enabled}#{SEPARATOR2}#{@screen_colors}#{SEPARATOR2}#{@screen_resolution}#{SEPARATOR2}#{@count_visits}"
    end
  end
  class Device_plugin < Device_platform
    def initialize(plugin)
      splitted_plugin = plugin.strip.split(SEPARATOR2)
      @browser = splitted_plugin[0]
      @browser_version = splitted_plugin[1]
      @os = splitted_plugin[2]
      @os_version = splitted_plugin[3]
      @flash_version = splitted_plugin[4]
      @java_enabled = splitted_plugin[5]
      @count_visits = splitted_plugin[6].to_i
    end
  end
  class Device_resolution < Device_platform
    def initialize(resolution)
      splitted_resolution = resolution.strip.split(SEPARATOR2)
      @browser = splitted_resolution[0]
      @browser_version = splitted_resolution[1]
      @os = splitted_resolution[2]
      @os_version = splitted_resolution[3]
      @screen_colors = splitted_resolution[4]
      @screen_resolution = splitted_resolution[5]
      @count_visits = splitted_resolution[6].to_i
    end
  end


  class Input
#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------
    INPUT = File.dirname(__FILE__) + "/../../input/"
    TMP = File.dirname(__FILE__) + "/../../tmp/"


    def initialize()
      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
    end

    def Building_matrix_and_pages(input_website)
      #TODO tester  Building_matrix_and_pages
      @logger.an_event.info ("Building matrix and page for <#{label}> for <#{date}> is starting")
      matrix_file = Flow.new(TMP, "matrix", input_website.label, input_website.date)
      pages_file = Flow.new(TMP, "pages", input_website.label, input_website.date)

      input_website.volumes.each { |volume|
        begin
          pob = ProgressBar.create(:title => "Loading vol <#{volume.vol}> of website input file", :length => 180, :starting_at => 0, :total => volume.count_lines(EOFLINE2), :format => '%t, %c/%C, %a|%w|')
          IO.foreach(volume.absolute_path, EOFLINE2, encoding: "BOM|UTF-8:-") { |p|
            page = Page.new(p)
            matrix_file.write(page.to_matrix)
            pages_file.write(page.to_page)
            pob.increment
          }
        rescue Exception => e
          @logger.an_event.debug e
        end
      }
      input_website.archive
      matrix_file.close
      pages_file.close
      matrix_file.archive_previous
      pages_file.archive_previous
      @logger.an_event.info ("Building matrix and page for <#{label}> is over")
    end

    def Building_landing_pages(traffic_source_file)
      #TODO valider le multi volume car la requete GA ne limite pas le nombre de resultats
      @logger.an_event.info ("Building landing pages for <#{traffic_source_file.label}> for <#{traffic_source_file.date}> is starting")

      if !traffic_source_file.exist?
        @logger.an_event.error("cannot build hourly landing page for #{traffic_source_file.label}")
        @logger.an_event.debug "inputs flow #{traffic_source_file.basename} file is missing"
        @logger.an_event.info ("Building landing pages for #{traffic_source_file.label} is over")
        return false
      end
      label = traffic_source_file.label
      date = traffic_source_file.date

      landing_pages_direct_file = Flow.new(TMP, "landing-pages-direct", traffic_source_file.label, traffic_source_file.date)
      landing_pages_referral_file = Flow.new(TMP, "landing-pages-referral", traffic_source_file.label, traffic_source_file.date)
      landing_pages_organic_file = Flow.new(TMP, "landing-pages-organic", traffic_source_file.label, traffic_source_file.date)

      traffic_source_file.volumes.each { |volume|
        begin
          pob = ProgressBar.create(:title => "Building landing pages", :length => 180, :starting_at => 0, :total => volume.count_lines(EOFLINE2), :format => '%t, %c/%C, %a|%w|')
          IO.foreach(volume.absolute_path, EOFLINE2, encoding: "BOM|UTF-8:-") { |p|
            page = Traffic_source.new(p)
            page.set_id_uri(label, date)
            if page.isknown?
              case page.medium
                when "(none)"
                  landing_pages_direct_file.write(page.to_landing_page)
                when "referral"
                  landing_pages_referral_file.write(page.to_landing_page)
                when "organic"
                  landing_pages_organic_file.write(page.to_landing_page)
                else
                  @logger.an_event.warn "medium unknown"
                  @logger.an_event.debug "medium <#{page.medium}>"
              end
            end
            pob.increment
          }
        rescue Exception => e
          @logger.an_event.debug e
        end
      }
      traffic_source_file.archive
      landing_pages_direct_file.close
      landing_pages_referral_file.close
      landing_pages_organic_file.close
      landing_pages_direct_file.archive_previous
      landing_pages_referral_file.archive_previous
      landing_pages_organic_file.archive_previous
      @logger.an_event.info ("Building landing pages for <#{traffic_source_file.label}> is over")
    end

    def Building_device_platform(label, date)
      #TODO valider le multi volume car la requete GA ne limite pas le nombre de resultats
      @logger.an_event.info ("Building device platform for <#{label}> for <#{date}> is starting")

      device_plugin = Flow.new(INPUT, "scraping-device-platform-plugin", label, date, 1)

      if !device_plugin.exist?
        @logger.an_event.error("cannot build device platform for <#{label}>")
        @logger.an_event.debug "inputs flow #{device_plugin.basename} file is missing"
        @logger.an_event.info ("Building device platform for <#{label}> is over")
        return false
      end

      device_resolution = Flow.new(INPUT, "scraping-device-platform-resolution", label, date, 1)

      if !device_resolution.exist?()
        @logger.an_event.error("cannot build device platform for <#{label}>")
        @logger.an_event.debug "inputs flow #{device_resolution.basename} file is missing"
        @logger.an_event.info ("Building device platform for <#{label}> is over")
        return false
      end

      device_plugins = device_plugin.load_to_array(EOFLINE2, Device_plugin).sort_by! { |a| [a.browser, a.browser_version, a.os, a.os_version] }
      device_resolutions = device_resolution.load_to_array(EOFLINE2, Device_resolution).sort_by! { |a| [a.browser, a.browser_version, a.os, a.os_version] }

      p = ProgressBar.create(:title => "Consolidation plugin & resolution files", :length => 180, :starting_at => 0, :total => device_plugins.size, :format => '%t, %c/%C, %a|%w|')
      device_platforms = []
      count_visits = 0
      device_plugins.each { |plugin|
        select_device_resolution = device_resolutions.collect { |x| x if x.browser == plugin.browser and
            x.browser_version == plugin.browser_version and
            x.os == plugin.os and
            x.os_version == plugin.os_version }
        select_device_resolution.compact!.each { |resolution|
          device = Device_platform.new(plugin, resolution)
          device_platforms << device
          count_visits += device.count_visits
          plugin.count_visits = plugin.count_visits - Common.min(plugin.count_visits, resolution.count_visits)
          break unless plugin.count_visits > 0
        }
        p.increment
      }

      device_platform_file = Flow.new(TMP, "device-platform", label, date)
      total = 0
      device_platforms.sort_by! { |a| [a.count_visits] }.reverse!.each { |device|
        device.count_visits = (device.count_visits.to_f * 100/count_visits)
        total += device.count_visits
        device_platform_file.write("#{device.to_s}#{EOFLINE2}")
      }
      device_resolution.archive
      device_plugin.archive
      device_platform_file.close
      device_platform_file.archive_previous
      @logger.an_event.info ("Building device platform for <#{label}> is over")
    end

    def Building_hourly_daily_distribution(input_distribution)
      #pas de gestion du multi-volume nécessaire car la requete vers ga limite le nombre de resultat
      @logger.an_event.info ("Building hourly daily distribution for #{input_distribution.label} for #{input_distribution.date} is starting")

      if !input_distribution.exist?
        @logger.an_event.error("cannot build hourly daily distribution for #{input_distribution.label}")
        @logger.an_event.debug "input flow #{input_distribution.basename} file is missing"
        @logger.an_event.info ("Building hourly daily distribution for #{input_distribution.label} is over")
        return false
      end
      tmp_distribution = Flow.new(TMP, "hourly-daily-distribution", input_distribution.label, input_distribution.date)

      distribution_per_day = ""
      i = 1
      day_save = ""
      p = ProgressBar.create(:title => "Building hourly daily distribution", :length => 180, :starting_at => 0, :total => input_distribution.count_lines(EOFLINE2), :format => '%t, %c/%C, %a|%w|')
      IO.foreach(input_distribution.absolute_path, EOFLINE2, encoding: "BOM|UTF-8:-") { |line|
        #30;00;20121130;21
        splitted_line = line.strip.split(SEPARATOR2)
        day = splitted_line[0]
        hour = splitted_line[1]
        date = splitted_line[2]
        count_visits = splitted_line[3]
        case day_save
          when ""
            distribution_per_day = "#{i}#{SEPARATOR2}#{count_visits}#{SEPARATOR4}"
          when day
            distribution_per_day += "#{count_visits}#{SEPARATOR4}"
          else
            distribution_per_day = distribution_per_day[0..distribution_per_day.size - 2]
            tmp_distribution.write("#{distribution_per_day}#{EOFLINE2}")
            i+=1
            distribution_per_day = "#{i}#{SEPARATOR2}#{count_visits}#{SEPARATOR4}"
        end
        day_save = day
        p.increment
      }
      tmp_distribution.write("#{distribution_per_day[0..distribution_per_day.size - 2]}#{EOFLINE2}")
      input_distribution.archive
      tmp_distribution.close
      tmp_distribution.archive_previous
      @logger.an_event.info ("Building hourly daily distribution for <#{input_distribution.label}> is over")
    end


    def Building_behaviour(input_behaviour)
      #pas de prise en compte du multi-volume car la requete ga limite le nombre de resultats
      @logger.an_event.info ("Building behaviour for #{input_behaviour.label} for #{input_behaviour.date} is starting")
      if !input_behaviour.exist?
        @logger.an_event.error("cannot build behaviour for #{input_behaviour.label}")
        @logger.an_event.debug "input flow #{input_behaviour.basename} file is missing"
        @logger.an_event.info ("Building behaviour for #{input_behaviour.label} is over")
        return false
      end
      tmp_behaviour = Flow.new(TMP, "behaviour", input_behaviour.label, input_behaviour.date)
      p = ProgressBar.create(:title => "Building behaviour", :length => 180, :starting_at => 0, :total => input_behaviour.count_lines(EOFLINE2), :format => '%t, %c/%C, %a|%w|')
      i = 1
      IO.foreach(input_behaviour.absolute_path, EOFLINE2, encoding: "BOM|UTF-8:-") { |line|
        splitted_line = line.strip.split(SEPARATOR2)
        #30;20121130;86.30377524143987;66.900790166813;52.25021949078139;1.9569798068481123;1139
        percent_new_visit = splitted_line[2].to_f.round(2)
        visit_bounce_rate = splitted_line[3].to_f.round(2)
        avg_time_on_site = splitted_line[4].to_f.round(2)
        page_views_per_visit = splitted_line[5].to_f.round(2)
        count_visits = splitted_line[6].to_i
        tmp_behaviour.write("#{i}#{SEPARATOR2}#{percent_new_visit}#{SEPARATOR2}#{visit_bounce_rate}#{SEPARATOR2}#{avg_time_on_site}#{SEPARATOR2}#{page_views_per_visit}#{SEPARATOR2}#{count_visits}#{EOFLINE2}")
        i +=1
        p.increment
      }
      input_behaviour.archive
      tmp_behaviour.close
      tmp_behaviour.archive_previous
      @logger.an_event.info ("Building behaviour for <#{input_behaviour.label}> is over")
    end
  end

end