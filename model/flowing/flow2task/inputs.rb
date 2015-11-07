#!/usr/bin/env ruby -w
# encoding: UTF-8
require 'socket'
require "ruby-progressbar"
require_relative "device"


module Flowing
  INPUT = File.dirname(__FILE__) + "/../../../input"
  TMP = File.dirname(__FILE__) + "/../../../tmp"

  SEPARATOR1="%SEP%"
  SEPARATOR2=";"
  SEPARATOR3="|"
  SEPARATOR4=","
  EOFLINE ="\n"
  PROGRESS_BAR_SIZE = 180

  class Inputs
#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------
    attr :policy_type,
         :label, :date

    def initialize(label, date, policy)
      @policy_type = policy
      @label = label
      @date = date
      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
    end

    def Building_device_platform
      #TODO Attention : le building_device_platforme, ne gère pas le multi-volume alors que la requete GA ne fixe pas de limite en nombre de resultats.
      #TODO en conséquence : seul le dernier volume émis par la requete GA sera utilisé par cette fonction => ce n'est pas bloquant, cela limite un peut le nombre de device
      #TODO il faut égaelement noté que pour le moment les resultats sur le site d'epilation sont inferieurs à 50ko pour le plugin et 1ko pour le resolution
      @logger.an_event.debug("Building device platform for <#{@policy_type}> <#{@label}> <#{@date}> is starting")
      begin
        device_plugin = Flow.new(INPUT, "scraping-device-platform-plugin", @policy_type, @label, @date, 1) #input
        raise IOError, "input flow <#{device_plugin.absolute_path}> is missing" unless device_plugin.exist?

        device_resolution = Flow.new(INPUT, "scraping-device-platform-resolution", @policy_type, @label, @date, 1) #input
        raise IOError, "input flow <#{device_resolution.absolute_path}> is missing" unless device_resolution.exist?

        device_plugins = device_plugin.load_to_array(EOFLINE, Device_plugin).sort_by! { |a| [a.browser, a.browser_version, a.os, a.os_version] }
        device_resolutions = device_resolution.load_to_array(EOFLINE, Device_resolution).sort_by! { |a| [a.browser, a.browser_version, a.os, a.os_version] }


        p = ProgressBar.create(:title => title("Building plugin resolution files"), :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => device_plugins.size, :format => '%t, %c/%C, %a|%w|')
        device_platforms = []
        count_visits = 0
        device_plugins.each { |plugin|
          select_device_resolution = device_resolutions.collect { |x| x if x.browser == plugin.browser and
              x.browser_version == plugin.browser_version and
              x.os == plugin.os and
              x.os_version == plugin.os_version
          }
          select_device_resolution.compact!.each { |resolution|
            @logger.an_event.debug resolution
            @logger.an_event.debug plugin
            device = Device_platform.new(plugin, resolution)
            @logger.an_event.debug device
            device_platforms << device
            count_visits += device.count_visits
            plugin.count_visits = plugin.count_visits - (plugin.count_visits < resolution.count_visits ? plugin.count_visits : resolution.count_visits)
            @logger.an_event.debug plugin
            break unless plugin.count_visits > 0
          }
          p.increment
        }

        device_platform_file = Flow.new(TMP, "device-platform", @policy_type, @label, @date) #output
        total = 0
        device_platforms.sort_by! { |a| [a.count_visits] }.reverse!.each { |device|
          device.count_visits = (device.count_visits.to_f * 100/count_visits)
          total += device.count_visits
          device_platform_file.write("#{device.to_s}#{EOFLINE}")
        }
        device_resolution.archive
        device_plugin.archive
        device_platform_file.close
        device_platform_file.archive_previous
      rescue Exception => e
        @logger.an_event.error("Building device platform for <#{@policy_type}> <#{@label}> is over #{e.message}")
      else
        @logger.an_event.debug("Building device platform for <#{@policy_type}> <#{@label}> is over")
      end

    end

    def Building_hourly_daily_distribution(input_distribution)
      #pas de gestion du multi-volume nécessaire car la requete vers ga limite le nombre de resultat
      @logger.an_event.debug("Building hourly daily distribution for <#{@policy_type}> <#{input_distribution.label}> <#{input_distribution.date}> is starting")

      begin
        raise IOError, "input flow <#{input_distribution.basename}> is missing" unless input_distribution.exist? #input

        tmp_distribution_count = Flow.new(TMP, "hourly-daily-distribution", @policy_type, input_distribution.label, input_distribution.date) #output

        distribution_per_day = ""
        i = 1
        day_save = ""

        p = ProgressBar.create(:title => title("Building hourly daily distribution", @policy_type, input_distribution.label, input_distribution.date), :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => input_distribution.count_lines(EOFLINE), :format => '%t, %c/%C, %a|%w|')
        IO.foreach(input_distribution.absolute_path, EOFLINE, encoding: "BOM|UTF-8:-") { |line|
          #30;00;20121130;21
          splitted_line = line.strip.split(SEPARATOR2)
          day = splitted_line[0]
          count_visits = splitted_line[3]
          case day_save
            when ""
              distribution_per_day = "#{i}#{SEPARATOR2}#{count_visits}#{SEPARATOR3}"
            when day
              distribution_per_day += "#{count_visits}#{SEPARATOR3}"
            else
              distribution_per_day = distribution_per_day[0..distribution_per_day.size - 2]
              tmp_distribution_count.write("#{distribution_per_day}#{EOFLINE}")
              i+=1
              distribution_per_day = "#{i}#{SEPARATOR2}#{count_visits}#{SEPARATOR3}"
          end
          day_save = day
          p.increment
        }
        tmp_distribution_count.write("#{distribution_per_day[0..distribution_per_day.size - 2]}#{EOFLINE}")

        input_distribution.archive
        tmp_distribution_count.close
        tmp_distribution_count.archive_previous
      rescue Exception => e
        @logger.an_event.error("Building hourly daily distribution for <#{@policy_type}> <#{input_distribution.label}> is over : #{e.message}")
      else
        @logger.an_event.debug("Building hourly daily distribution for <#{@policy_type}> <#{input_distribution.label}> is over")
      end
    end

    def Building_behaviour(input_behaviour)
      #pas de prise en compte du multi-volume car la requete ga limite le nombre de resultats
      @logger.an_event.debug("Building behaviour for <#{@policy_type}> <#{input_behaviour.label}> <#{input_behaviour.date}> is starting")
      begin
        raise IOError, "input flow <#{input_behaviour.basename}> is missing" unless input_behaviour.exist?

        tmp_behaviour = Flow.new(TMP, "behaviour", @policy_type, input_behaviour.label, input_behaviour.date) #output
        p = ProgressBar.create(:title => title("Building behaviour",@policy_type,input_behaviour.label,input_behaviour.date), :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => input_behaviour.count_lines(EOFLINE), :format => '%t, %c/%C, %a|%w|')
        i = 1
        input_behaviour.foreach(EOFLINE) { |line|
          splitted_line = line.strip.split(SEPARATOR2)
          #30;20121130;86.30377524143987;66.900790166813;52.25021949078139;1.9569798068481123;1139
          percent_new_visit = splitted_line[2].to_f.round(2)
          visit_bounce_rate = splitted_line[3].to_f.round(2)
          avg_time_on_site = splitted_line[4].to_f.round(2)
          page_views_per_visit = splitted_line[5].to_f.round(2)
          count_visits = splitted_line[6].to_i
          tmp_behaviour.write("#{i}#{SEPARATOR2}#{percent_new_visit}#{SEPARATOR2}#{visit_bounce_rate}#{SEPARATOR2}#{avg_time_on_site}#{SEPARATOR2}#{page_views_per_visit}#{SEPARATOR2}#{count_visits}#{EOFLINE}")
          i +=1
          p.increment
        }
        input_behaviour.archive
        tmp_behaviour.close
        tmp_behaviour.archive_previous
      rescue Exception => e
        @logger.an_event.error("Building behaviour for <#{@policy_type}> <#{input_behaviour.label}> is over : #{e.message}")
      else
        @logger.an_event.debug("Building behaviour for <#{@policy_type}> <#{input_behaviour.label}> is over")
      end
    end

    private
    def title(action, policy = @policy_type, label = @label, date = @date)
      [action, policy, label, date].join(" | ")
    end
  end

end


