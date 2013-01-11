#!/usr/bin/env ruby -w
# encoding: UTF-8


require 'socket'

#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------

require File.dirname(__FILE__) + '/../lib/logging'
require File.dirname(__FILE__) + '/../lib/common'

module Building_inputs
#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------
  INPUT = File.dirname(__FILE__) + "/../input/"
  TMP = File.dirname(__FILE__) + "/../tmp/"
  SEPARATOR="%SEP%"
  EOFLINE="%EOFL%"
  SEPARATOR2=";"
  SEPARATOR4="|"
  EOFLINE2 ="\n"
  LOG_FILE = File.dirname(__FILE__) + "/../log/" + File.basename(__FILE__, ".rb") + ".log"
  $log_file = LOG_FILE
  $b = false

  class Page
    NO_LINK = "*"
    attr :id_uri,
         :hostname,
         :page_path,
         :title,
         :links

    def initialize(page)
      splitted_page = page.split(SEPARATOR)
      @id_uri = splitted_page[0].to_i
      if @id_uri == 24185
        $b = true
      end
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
      splitted_page = page.split(SEPARATOR)
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
  class Chosen_device_platform < Device_platform
    def initialize(device)
      splitted_device = device.strip.split(SEPARATOR2)
      @browser = splitted_device[0]
      @browser_version = splitted_device[1]
      @os = splitted_device[2]
      @os_version = splitted_device[3]
      @flash_version = splitted_device[4]
      @java_enabled = splitted_device[5]
      @screen_colors = splitted_device[6]
      @screen_resolution = splitted_device[7]
      @count_visits = splitted_device[8].to_f
    end

    def to_s(*a)
      "#{@browser}#{SEPARATOR2}#{@browser_version}#{SEPARATOR2}#{@os}#{SEPARATOR2}#{@os_version}#{SEPARATOR2}#{@flash_version}#{SEPARATOR2}#{@java_enabled}#{SEPARATOR2}#{@screen_colors}#{SEPARATOR2}#{@screen_resolution}"
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
#inputs

# local


  def Building_matrix_and_pages(label, date)
    information("Building matrix and page for #{label} for #{date} is starting")
    matrix_file = open_file(TMP, "matrix", label, date)
    matrix_file.sync = true
    pages_file = open_file(TMP, "pages", label, date)
    pages_file.sync = true

    vol = 1
    eof = false
    while !eof
      begin
        website_file_id = id_file(INPUT, "website", label, date, vol)
        website_file = File.open(website_file_id, "r:BOM|UTF-8:-")
        if  !website_file.nil?
          count_line = File.foreach(website_file, EOFLINE, encoding: "BOM|UTF-8:-").inject(0) { |c, line| c+1 }
          pob = ProgressBar.create(:title => File.basename(website_file), :length => 180, :starting_at => 0, :total => count_line, :format => '%t, %c/%C, %a|%w|')
          IO.foreach(website_file, EOFLINE, encoding: "BOM|UTF-8:-") { |p|
            #TODO resoudre le pb d'indice lors du scrapping
            #p p if $b
            page = Page.new(p)
            matrix_file.write(page.to_matrix)
            pages_file.write(page.to_page)
            pob.increment
          }
          vol += 1
        else
          Logging.send(LOG_FILE, Logger::DEBUG, "file <website-#{label}-#{date}-#{vol}> is not found")
          eof = true
        end
      rescue Errno::ENOENT => e
        Logging.send(LOG_FILE, Logger::DEBUG, "file <#{website_file}> no exist")
        eof = true
      rescue Exception => e
        eof = true
        Logging.send(LOG_FILE, Logger::ERROR, "#{e.message}", __LINE__)
      end
    end
    matrix_file.close
    pages_file.close
    information("Building matrix and page for #{label} is over")
  end

  def Building_landing_pages(label, date)
    information("Building landing pages for #{label} for #{date} is starting")
    landing_pages_direct_file = open_file(TMP, "landing-pages-direct", label, date)
    landing_pages_direct_file.sync = true
    landing_pages_referral_file = open_file(TMP, "landing-pages-referral", label, date)
    landing_pages_referral_file.sync = true
    landing_pages_organic_file = open_file(TMP, "landing-pages-organic", label, date)
    landing_pages_organic_file.sync = true
    vol = 1
    eof = false
    while !eof
      begin
        traffic_source_file = id_file(INPUT, "traffic-source-landing-page", label, date, vol)
        #traffic_source_file = File.open(traffic_source_file_id, "r:BOM|UTF-8:-")
        if  !traffic_source_file.nil?
          count_line = File.foreach(traffic_source_file, EOFLINE2, encoding: "BOM|UTF-8:-").inject(0) { |c, line| c+1 }
          pob = ProgressBar.create(:title => File.basename(traffic_source_file), :length => 180, :starting_at => 0, :total => count_line, :format => '%t, %c/%C, %a|%w|')
          IO.foreach(traffic_source_file, EOFLINE2, encoding: "BOM|UTF-8:-") { |p|
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
                  Logging.send(LOG_FILE, Logger::ERROR, "medium unknown : #{ page.medium}")
              end
            end
            pob.increment
          }
          vol += 1
        else
          Logging.send(LOG_FILE, Logger::DEBUG, "file <traffic-source-landing-page-#{label}-#{date}-#{vol}> is not found")
          eof = true
        end
      rescue Exception => e
        eof = true
        Logging.send(LOG_FILE, Logger::ERROR, "#{e.message}", __LINE__)
      end
    end

    landing_pages_direct_file.close
    landing_pages_referral_file.close
    landing_pages_organic_file.close
    information("Building landing pages for #{label} is over")
  end

  def Building_device_platform(label, date)
    information("Building device platform for #{label} for #{date} is starting")

    device_plugin = id_file(INPUT, "device-platform-plugin", label, date)


    if !File.exist?(device_plugin)
      alert("Building_device_platform for #{label} fails because inputs Device_platform_plugin file is missing")
      return false
    end
    device_resolution = id_file(INPUT, "device-platform-resolution", label, date)

    if !File.exist?(device_resolution)
      alert("Building_device_platform for #{label} fails because inputs Device_platform_resolution file is missing")
      return false
    end
    device_plugins = []
    IO.foreach(device_plugin, EOFLINE2, encoding: "BOM|UTF-8:-") { |plugin|
      device_plugins << Device_plugin.new(plugin)
    }

    device_plugins.sort_by! { |a| [a.browser, a.browser_version, a.os, a.os_version] }

    device_resolutions = []
    IO.foreach(device_resolution, EOFLINE2, encoding: "BOM|UTF-8:-") { |resolution|
      device_resolutions << Device_resolution.new(resolution)
    }
    device_resolutions.sort_by! { |a| [a.browser, a.browser_version, a.os, a.os_version] }

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

    device_platform_file = open_file(TMP, "device-platform", label, date)
    total = 0
    device_platforms.sort_by! { |a| [a.count_visits] }.reverse!.each { |device|
      device.count_visits = (device.count_visits.to_f * 100/count_visits)
      total += device.count_visits
      device_platform_file.write("#{device.to_s}#{EOFLINE2}")
    }
    device_platform_file.close
    information("Building device platform for #{label} is over")
  end

  def Building_hourly_daily_distribution(label, date)
    information("Building hourly daily distribution for #{label} for #{date} is starting")
    distribution = id_file(INPUT, "hourly-daily-distribution", label, date)
    if !File.exist?(distribution)
      alert("Building hourly daily distribution for #{label} fails because inputs Hourly-daily-distribution file is missing")
      return false
    end
    distribution_per_day_file = open_file(TMP, "hourly-daily-distribution", label, date)
    distribution_per_day_file.sync = true
    distribution_per_day = ""
    i = 1
    day_save = ""
    count_line = File.foreach(distribution, EOFLINE2, encoding: "BOM|UTF-8:-").inject(0) { |c, line| c+1 }
    p = ProgressBar.create(:title => "Building hourly daily distribution", :length => 180, :starting_at => 0, :total => count_line, :format => '%t, %c/%C, %a|%w|')
    IO.foreach(distribution, EOFLINE2, encoding: "BOM|UTF-8:-") { |line|
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
          distribution_per_day_file.write("#{distribution_per_day}#{EOFLINE2}")
          i+=1
          distribution_per_day = "#{i}#{SEPARATOR2}#{count_visits}#{SEPARATOR4}"
      end
      day_save = day
      p.increment
    }
    distribution_per_day_file.write("#{distribution_per_day[0..distribution_per_day.size - 2]}#{EOFLINE2}")
    distribution_per_day_file.close
    information("Building hourly daily distribution for #{label} is over")
  end


  def Building_behaviour(label, date)
    information("Building behaviour for #{label} for #{date} is starting")
    behaviour_input = id_file(INPUT, "behaviour", label, date)

    if !File.exist?(behaviour_input)
      alert("Building behaviour for #{label} fails because inputs behaviour file is missing")
      return false
    end
    behaviour_file = open_file(TMP, "behaviour", label, date)
    behaviour_file.sync = true
    count_line = File.foreach(behaviour_input, EOFLINE2, encoding: "BOM|UTF-8:-").inject(0) { |c, line| c+1 }
    p = ProgressBar.create(:title => "Building hourly daily distribution", :length => 180, :starting_at => 0, :total => count_line, :format => '%t, %c/%C, %a|%w|')
    i = 1
    IO.foreach(behaviour_input, EOFLINE2, encoding: "BOM|UTF-8:-") { |line|
      splitted_line = line.strip.split(SEPARATOR2)
      #30;20121130;86.30377524143987;66.900790166813;52.25021949078139;1.9569798068481123;1139
      percent_new_visit = splitted_line[2].to_f.round(2)
      visit_bounce_rate = splitted_line[3].to_f.round(2)
      avg_time_on_site = splitted_line[4].to_f.round(2)
      page_views_per_visit = splitted_line[5].to_f.round(2)
      count_visits = splitted_line[6].to_i
      behaviour_file.write("#{i}#{SEPARATOR2}#{percent_new_visit}#{SEPARATOR2}#{visit_bounce_rate}#{SEPARATOR2}#{avg_time_on_site}#{SEPARATOR2}#{page_views_per_visit}#{SEPARATOR2}#{count_visits}#{EOFLINE2}")
      i +=1
      p.increment
    }
    behaviour_file.close
    information("Building behaviour for #{label} is over")
  end

  def Choosing_landing_pages(label, date, direct_medium_percent, organic_medium_percent, referral_medium_percent, count_visit)
    information("Choosing landing pages for #{label} for #{date} is starting")
      file = id_file(TMP, "chosen-landing-pages", label, date)
      File.delete(file) if File.exist?(file)
    Common.archive_file(TMP, "chosen-landing-pages", label)
      result = Choosing_landing(label, date, "direct", direct_medium_percent, count_visit) &&
          Choosing_landing(label, date, "referral", referral_medium_percent, count_visit) &&
          Choosing_landing(label, date, "organic", organic_medium_percent, count_visit)
      alert("Choosing landing pages for #{label} fails because inputs Landing files are missing") unless result
      information("Choosing landing pages for #{label} is over")
      #execute_next_step("Building_visits", label, date) if result

  end


  def Choosing_device_platform(label, date, count_visits)

    information("Choosing device platform for #{label} for #{date} is starting")

    device_platform = select_file(TMP, "device-platform", label, date)

    if device_platform.nil?
      alert("Choosing_device_platform for #{label} fails because inputs #{device_platform} file for #{label} in date of #{date} is missing")
      return false
    end
    chosen_device_platform_file = open_file(TMP, "chosen-device-platform", label, date)
    total_visits = 0
    pob = ProgressBar.create(:title => File.basename(device_platform), :length => 180, :starting_at => 0, :total => count_visits, :format => '%t, %c/%C, %a|%w|')
    IO.foreach(device_platform, EOFLINE2, encoding: "BOM|UTF-8:-") { |device|
      chosen_device = Chosen_device_platform.new(device)
      count_device = Common.max((chosen_device.count_visits * count_visits / 100).to_i, 1)
      count_device = count_visits - total_visits if total_visits + count_device > count_visits # pour eviter de peasser le nombre de visite attendues
      total_visits += count_device
      count_device.times { chosen_device_platform_file.write("#{chosen_device.to_s}#{EOFLINE2}"); pob.increment }

    }
    chosen_device_platform_file.close
    information("Choosing device platform for #{label} is over")
    #execute_next_step("Building_visits", label, date)
  end

  #private
  def Choosing_landing(label, date, medium_type, medium_percent, count_visit)
    landing_pages = select_file(TMP, "landing-pages-#{medium_type}", label, date)
    return false if landing_pages.nil?

    landing_pages_file = File.open(landing_pages, "r:utf-8")
    medium_count = (medium_percent * count_visit / 100).to_i
    landing_pages_file_lines = File.foreach(landing_pages).inject(0) { |c, line| c+1 }

    chosen_landing_pages_file = File.open(id_file(TMP, "chosen-landing-pages", label, date), "a:utf-8") #TMP + "chosen_landing_pages-#{label}-#{date}.txt", "a:utf-8")
    chosen_landing_pages_file.sync =true

    p = ProgressBar.create(:title => "#{medium_type} landing pages", :length => 180, :starting_at => 0, :total => medium_count, :format => '%t, %c/%C, %a|%w|')
    while medium_count > 0 and landing_pages_file_lines > 0
      chose = rand(landing_pages_file_lines - 1) + 1
      landing_pages_file.rewind
      (chose - 1).times { landing_pages_file.readline(EOFLINE2) }
      page = landing_pages_file.readline(EOFLINE2)
      chosen_landing_pages_file.write(page)
      medium_count -= 1
      p.increment
    end
    chosen_landing_pages_file.close
    landing_pages_file.close
    true
  end

  def information(msg)
    Common.information(msg)
  end

  def alert(msg)
    Common.alert(msg)
  end

  def execute_next_step(task, label, date)
    Common.execute_next_task(task, label, date)
  end

  def select_file(dir, type_file, label, date, vol=nil)
    Common.select_file(dir, type_file, label, date, vol)
  end

  def id_file(dir, type_file, label, date, vol=nil, ext="txt")
    Common.id_file(dir, type_file, label, date, vol, ext)
  end

  def open_file(dir, type_file, label, date, vol=nil, ext="txt")
    Common.open_file(dir, type_file, label, date, vol, ext)
  end

  module_function :Building_matrix_and_pages
  module_function :Building_landing_pages
  module_function :Building_device_platform
  module_function :Building_hourly_daily_distribution
  module_function :Building_behaviour
  module_function :Choosing_device_platform
  module_function :Choosing_landing_pages

  #private
  module_function :Choosing_landing
  module_function :execute_next_step
  module_function :information
  module_function :alert
  module_function :select_file
  module_function :id_file
  module_function :open_file

end