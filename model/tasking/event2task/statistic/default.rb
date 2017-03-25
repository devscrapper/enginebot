#!/usr/bin/env ruby -w
# encoding: UTF-8

require 'ruby-progressbar'
require 'fileutils'

require_relative '../../../../lib/logging'
require_relative '../../../flow'

require_relative 'statistic'
#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------


module Tasking
  module Statistic


    class Default < Statistic
#------------------------------------------------------------------------------------------
# Cette classe apporte un comportement ou des valeurs par defaut pour des sites Web qui
# n'ont pas de profil GoogleAnalytics. Si un Site utilise un outils de statistics different
# de Google, il faudra mettre en oeuvre une classe dédiée à ce fournisseur de statisitic
# pour les methodes suivantes :
# device_platforme_plugin
# device_platform_resolution
# hourly_daily_distribution
# behaviour
#------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------


      attr :devices,
           :distribution


      def initialize(website_label, date, policy_type)
        super(website_label, date, policy_type)
        @logger = Logging::Log.new(self, :staging => $staging, :id_file => File.basename(__FILE__, ".rb"), :debugging => $debugging)

        begin
          parameters = Parameter.new(__FILE__)
        rescue Exception => e
          @logger.an_event.error "cannot load parameters file <#{File.basename(__FILE__, ".rb") + ".yml"}> : #{e.message}"
        else
          $staging = parameters.environment
          $debugging = parameters.debugging
          @devices = parameters.devices
          @distribution = parameters.distribution
        end


      end


#--------------------------------------------------------------------------------------------------------------
# scraping_device_platform_plugin
#--------------------------------------------------------------------------------------------------------------
# le contenu du fichier default.yml contient la liste des combinaisons browser, browser version, os, os version
# disponible   :
#       devices: [
#       [Windows, 7, Chrome, 39.0.2139.3, 25],
#       [Windows, 7, Chrome, 23.0.1271.97, 25],
#       [Windows, 7, Internet Explorer, 11.0, 20],
#       [Windows, 7, Internet Explorer, 9.0, 10],
#       [Windows, 7, Firefox, 24.0, 10],
#       [Windows, 7, Firefox, 19.0, 10]
#       ]
#input :
# label du site,
# date de scraping,
# id site
#Output :
# RAS : le fichier scraping_device_platforme_plugin est posté vers enginebot
# --------------------------------------------------------------------------------------------------------------
# format d'une ligne du fichier :
# Internet Explorer;9.0;Windows;7;11.5 r502;Yes;No;8380;
# @browser;@browser_version;@os;@os_version;@flashversion;@javaenabled;@count_visits
# --------------------------------------------------------------------------------------------------------------

      def device_platform_plugin

        execute("scraping-device-platform-plugin",
                @devices.map { |device| device[0..3] + ["flash_version", "javaenabled", "ismobile", device[4]] })
      end


#--------------------------------------------------------------------------------------------------------------
# scraping_device_platform_resolution
#--------------------------------------------------------------------------------------------------------------
# le contenu du fichier default.yml contient la liste des combinaisons browser, browser version, os, os version
# disponible   :
#       devices: [
#       [Windows, 7, Chrome, 39.0.2139.3],
#       [Windows, 7, Chrome, 23.0.1271.97],
#       [Windows, 7, Internet Explorer, 11.0],
#       [Windows, 7, Internet Explorer, 9.0],
#       [Windows, 7, Firefox, 24.0],
#       [Windows, 7, Firefox, 19.0]
#       ]
#input :
# label du site,
# date de scraping,
# id site
#Output :
# RAS : le fichier device_platform_resolution est posté vers enginebot
# --------------------------------------------------------------------------------------------------------------
# format d'une ligne du fichier :
# Internet Explorer;8.0;Windows;XP;32-bit;1280x1024;No;2586;
# @browser;@browser_version;@os;@os_version;@screencolor;@screenresolution;ismobile;@count_visits
# --------------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------------------

      def device_platform_resolution

        execute("scraping-device-platform-resolution",
                @devices.map { |device| device[0..3] + ["screencolor", "1280x1024", "ismobile", device[4]] })
      end


#--------------------------------------------------------------------------------------------------------------
# Scraping_hourly_daily_distribution
#--------------------------------------------------------------------------------------------------------------21;00;20130421;21;
# 21;01;20130421;7;
# 21;02;20130421;4;
# 21;03;20130421;5;
# 21;04;20130421;3;
# 21;05;20130421;1;
# 21;06;20130421;4;
# 21;07;20130421;6;
# 21;08;20130421;16;
# 21;09;20130421;32;
# 21;10;20130421;35;
#...
# 27;18;20130427;54;
# 27;19;20130427;49;
# 27;20;20130427;41;
# 27;21;20130427;36;
# 27;22;20130427;34;
# 27;23;20130427;26;
# --------------------------------------------------------------------------------------------------------------


      def hourly_daily_distribution

        data = []
        7.times { |i|
          @distribution.each { |d|
            data << [i + 1, d[0], "not use", d[1]]
          }
        }

        execute("scraping-hourly-daily-distribution",
                data)

      end


#--------------------------------------------------------------------------------------------------------------
# Scraping_behaviour
#--------------------------------------------------------------------------------------------------------------
# 22;20140622;90.63829787234042;63.51063829787233;136.9936170212766;2.7638297872340427;940;
# 23;20140623;88.80718954248366;58.98692810457516;83.39133986928104;2.270424836601307;1224;
# 24;20140624;88.15126050420167;61.34453781512605;76.05126050420168;2.1218487394957983;1190;
# 25;20140625;88.54271356783919;58.59296482412061;82.66834170854271;2.2733668341708544;995;
# 26;20140626;89.94614003590664;61.93895870736086;102.40754039497307;2.284560143626571;1114;
# 27;20140627;87.45945945945945;64.10810810810811;120.55243243243243;2.5286486486486486;925;
# 28;20140628;89.34624697336562;62.95399515738499;130.67796610169492;2.6634382566585955;826;
# num day;date;percent_new_visit;visit_bounce_rate;avg_time_on_site;page_views_per_visit;count_visits

# --------------------------------------------------------------------------------------------------------------
      def behaviour
        data = []

        7.times { |i| data << [i + 1, #0
                               "not use", #1
                               100, #2 percent_new_visit
                               Random.new.rand(80..90), #3 visit_bounce_rate
                               Random.new.rand(60..300), # 4 avg_time_on_site
                               Random.new.rand(3..11), #5 page_views_per_visit
                               Random.new.rand(50..100)] } #6 count_visits

        execute("scraping-behaviour",
                data)
      end


      private

    end
  end
end