#!/usr/bin/env ruby -w
# encoding: UTF-8
require 'socket'
require "ruby-progressbar"

module Flowing
  SEPARATOR1="%SEP%"
  SEPARATOR2=";"
  SEPARATOR3="|"
  SEPARATOR4=","
  EOFLINE ="\n"

  class Page
    class PageException < StandardError
    end

    attr_accessor :id_uri,
                  :hostname,
                  :page_path,
                  :title,
                  :links

    def initialize(page)
      splitted_page = page.split(SEPARATOR1)
      @id_uri = splitted_page[0].to_i
      @hostname = splitted_page[1]
      @page_path = splitted_page[2]
      @title = splitted_page[3]
      raise PageException, "page malformed" if @id_uri.nil? or @hostname.nil? or @page_path.nil? or @title.nil?
      @links = splitted_page[4][1..splitted_page[4].size - 2].split(SEPARATOR4).map { |s| s.to_i } unless splitted_page[4].nil?
    end

    def to_matrix(*a)
      "#{@id_uri}#{SEPARATOR2}#{@links.join SEPARATOR4}#{EOFLINE}"
    end

    def to_page(*a)
      "#{@id_uri}#{SEPARATOR2}#{@hostname}#{SEPARATOR2}#{@page_path}#{SEPARATOR2}#{@title}#{EOFLINE}"
    end
  end

  class Traffic_source
    class Traffic_sourceException < StandardError
    end
    TMP = File.dirname(__FILE__) + "/../../tmp"
    NOT_FOUND = 0
    attr :id_uri,
         :hostname,
         :landing_page_path,
         :referral_path,
         :source,
         :medium,
         :keyword


    def initialize(page)
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
      "#{@id_uri}#{SEPARATOR2}#{@referral_path}#{SEPARATOR2}#{@source}#{SEPARATOR2}#{@medium}#{SEPARATOR2}#{@keyword}#{EOFLINE}"
    end

    def set_id_uri_mem(label, date, pages_array)
      @id_uri = NOT_FOUND
      max = pages_array.size
      min = 1
      id = nil
      value = @hostname + @landing_page_path
      found = false
      while max - min > 1 and not(found)
        i = ((max - min) / 2).round(0) + min
        crt = pages_array[i].split(";")
        @id_uri = crt[0].to_i if found =(crt[1] + crt[2] == value)
        max = i if crt[1] + crt[2] > value
        min = i  if crt[1] + crt[2] < value
      end
    end

    def set_id_uri_disk(label, date, pages_file)
      @id_uri = NOT_FOUND
      raise IOError, "tmp flow <#{pages_file.basename}> is missing" unless pages_file.exist?
      pages_file.foreach(EOFLINE) { |page|
        splitted_page = page.split(SEPARATOR2)
        if splitted_page[1] == @hostname and splitted_page[2] == @landing_page_path
          @id_uri = splitted_page[0].to_i
          break
        end
      }
    end

    def isknown?()
      !(@id_uri == NOT_FOUND)
    end

    def is_in_pages(label, date, pages)
      set_id_uri_disk(label, date, pages) if pages.is_a?(Flow)
      set_id_uri_mem(label, date, pages) if pages.is_a?(Array)
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
      @count_visits = plugin.count_visits < resolution.count_visits ? plugin.count_visits : resolution.count_visits
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
      @is_mobile = splitted_plugin[6]
      @count_visits = splitted_plugin[7].to_i
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
      @is_mobile = splitted_resolution[6]
      @count_visits = splitted_resolution[7].to_i
    end
  end


  class Inputs
#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------
    INPUT = File.dirname(__FILE__) + "/../../input"
    TMP = File.dirname(__FILE__) + "/../../tmp"
    SEPARATOR2=";"

    def initialize()
      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
    end

    def Building_matrix_and_pages(input_website)
      @logger.an_event.info("Building matrix and page for <#{input_website.label}> for <#{input_website.date}> is starting")
      begin
        matrix_file = Flow.new(TMP, "matrix", input_website.label, input_website.date) #output
        pages_file = Flow.new(TMP, "pages", input_website.label, input_website.date) #output

        raise IOError, "a volume of input flow <#{input_website.basename}> is missing" unless input_website.volumes_exist?
        #raise IOError, "a volume of input flow <#{input_website.basename}> is missing" unless (input_website.volumes_exist? and
        #    input_website.volume_exist?(0))
        #leaves = Flow.new(input_website.dir, input_website.type_flow, input_website.label, input_website.date, 0, input_website.ext).readlines(EOFLINE).map { |leaf| leaf.strip.to_i } #input
        #@logger.an_event.debug leaves

        input_website.volumes.each { |volume|
          @logger.an_event.info "Loading vol <#{volume.vol}> of website input file"
          pob = ProgressBar.create(:length => 180, :starting_at => 0, :total => volume.count_lines(EOFLINE), :format => '%t, %c/%C, %a|%w|')
          #--------------------------------------------------------------------------------------------------------------
          # IMPORTANT
          #--------------------------------------------------------------------------------------------------------------
          # on ne prend pas en compte le fichier des feuilles car :
          # si on supprime une page qui est une feuille alors toutes les pages qui pointent sur elle et qui n'ont quelle
          # comme lien alors on crée une nouvelle feuille. cela risque d'augmenter le nombre de feuille plutot que de le reduire
          # pour corriger cela il faudra rechercher à nouveau les feuilles et les supprimer jusqu'à ce qu'il ny en ait plus => couteux pour quel benefice
          # et risqué, car en fonction de la topologie du site (exemple : un arbre sans cycle) il pourrait ne plus y avoir de page de conserver
          #--------------------------------------------------------------------------------------------------------------
          #if leaves.empty?
          volume.foreach(EOFLINE) { |p|
            # si il n'y a pas de feuille
            begin
              page = Page.new(p)
              matrix_file.write(page.to_matrix)
              pages_file.write(page.to_page)
              pob.increment
            rescue Exception => e
              @logger.an_event.error "cannot build matrix and page for <#{input_website.label}> for <#{input_website.date}>"
              @logger.an_event.debug p
              @logger.an_event.debug page
              @logger.an_event.debug e
            end
          }
          #else
          #  volume.foreach(EOFLINE) { |p|
          #    # si il y a au moins une feuille on les supprime
          #    begin
          #      page = Page.new(p)
          #      # sauvegarde de la page dans matrix et page ssi ce n'est pas une feuille
          #      unless leaves.include?(page.id_uri)
          #        @logger.an_event.debug page.links
          #        page.links = page.links - leaves #on enleve les feuilles des links de la page
          #        matrix_file.write(page.to_matrix)
          #        pages_file.write(page.to_page)
          #      end
          #      pob.increment
          #    rescue Exception => e
          #      @logger.an_event.debug p
          #      @logger.an_event.debug page
          #      @logger.an_event.debug e
          #      @logger.an_event.error "cannot build matrix and page for <#{input_website.label}> for <#{input_website.date}>"
          #    end
          #  }
          #end
          volume.archive
        }
        # on archive le volume 0 de input flow website
        #input_website.vol = 0
        #input_website.archive
        matrix_file.close
        pages_file.close
        matrix_file.archive_previous
        pages_file.archive_previous

      rescue Exception => e
        @logger.an_event.debug e
        @logger.an_event.error "cannot build matrix and page for <#{input_website.label}> for <#{input_website.date}>"
      end
      @logger.an_event.info("Building matrix and page for <#{input_website.label}> is over")
    end

    def Building_landing_pages(traffic_source_file, pages_in_mem)
      @logger.an_event.info "Building landing pages for <#{traffic_source_file.label}> for <#{traffic_source_file.date}> is starting"
      begin
        pages_file = Flow.new(TMP, "pages", traffic_source_file.label, traffic_source_file.date).last
        raise IOError, "tmp flow pages for <#{traffic_source_file.label}> for <#{traffic_source_file.date}> is missing" if pages_file.nil? #input
        raise IOError, "input flow <#{traffic_source_file.basename}> is missing" unless traffic_source_file.exist? #input
        label = traffic_source_file.label
        date = traffic_source_file.date

        landing_pages_direct_file = Flow.new(TMP, "landing-pages-direct", traffic_source_file.label, traffic_source_file.date) #output
        landing_pages_referral_file = Flow.new(TMP, "landing-pages-referral", traffic_source_file.label, traffic_source_file.date) #output
        landing_pages_organic_file = Flow.new(TMP, "landing-pages-organic", traffic_source_file.label, traffic_source_file.date) #output

        #on tri le fichier de page sur le hostname et le landing_page_path pour accelerer la recherche de page qui s'appuie sur une dichotomie
        pages_file.sort{ |line| [line.split(SEPARATOR2)[1], line.split(SEPARATOR2)[2]]}
        pages = pages_file.load_to_array(EOFLINE) if pages_in_mem
        pages = pages_file unless pages_in_mem

        traffic_source_file.volumes.each { |volume|
          @logger.an_event.info "Loading vol <#{volume.vol}> of scraping-traffic-source-landing input file"
          pob = ProgressBar.create(:length => 180, :starting_at => 0, :total => volume.count_lines(EOFLINE), :format => '%t, %c/%C, %a|%w|')
          volume.foreach(EOFLINE) { |p|
            source_page = Traffic_source.new(p)
            #source_page.set_id_uri(label, date)
            #if source_page.isknown?
            case source_page.medium
              when "(none)"
                landing_pages_direct_file.write(source_page.to_landing_page)
              when "referral"
                landing_pages_referral_file.write(source_page.to_landing_page)
              when "organic"
                landing_pages_organic_file.write(source_page.to_landing_page)
              else
                @logger.an_event.warn "medium unknown"
                @logger.an_event.debug "medium <#{source_page.medium}>"
            end if source_page.is_in_pages(label, date, pages)
            #end
            pob.increment
          }
          volume.archive
        }
        pages_file.close
        landing_pages_direct_file.close
        landing_pages_referral_file.close
        landing_pages_organic_file.close
        landing_pages_direct_file.archive_previous
        landing_pages_referral_file.archive_previous
        landing_pages_organic_file.archive_previous
      rescue Exception => e
        @logger.an_event.debug e
        @logger.an_event.error "cannot build landing pages for <#{traffic_source_file.label}>"
      end
      @logger.an_event.info("Building landing pages for <#{traffic_source_file.label}> is over")
    end

    def Building_device_platform(label, date)
      #TODO Attention : le building_device_platforme, ne gère pas le multi-volume alors que la requete GA ne fixe pas de limite en nombre de resultats.
      #TODO en conséquence : seul le dernier volume émis par la requete GA sera utilisé par cette fonction => ce n'est pas bloquant, cela limite un peut le nombre de device
      #TODO il faut égaelement noté que pour le moment les resultats sur le site d'epilation sont inferieurs à 50ko pour le plugin et 1ko pour le resolution
      @logger.an_event.info("Building device platform for <#{label}> for <#{date}> is starting")
      begin
        device_plugin = Flow.new(INPUT, "scraping-device-platform-plugin", label, date, 1) #input
        raise IOError, "input flow <#{device_plugin.basename}> is missing" unless device_plugin.exist?

        device_resolution = Flow.new(INPUT, "scraping-device-platform-resolution", label, date, 1) #input
        raise IOError, "input flow <#{device_resolution.basename}> is missing" unless device_resolution.exist?

        device_plugins = device_plugin.load_to_array(EOFLINE, Device_plugin).sort_by! { |a| [a.browser, a.browser_version, a.os, a.os_version] }
        device_resolutions = device_resolution.load_to_array(EOFLINE, Device_resolution).sort_by! { |a| [a.browser, a.browser_version, a.os, a.os_version] }

        p = ProgressBar.create(:title => "Consolidation plugin & resolution files", :length => 180, :starting_at => 0, :total => device_plugins.size, :format => '%t, %c/%C, %a|%w|')
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

        device_platform_file = Flow.new(TMP, "device-platform", label, date) #output
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
        @logger.an_event.debug e
        @logger.an_event.error("cannot build device platform for <#{label}>")
      end
      @logger.an_event.info("Building device platform for <#{label}> is over")
    end

    def Building_hourly_daily_distribution(input_distribution)
      #pas de gestion du multi-volume nécessaire car la requete vers ga limite le nombre de resultat
      @logger.an_event.info("Building hourly daily distribution for #{input_distribution.label} for #{input_distribution.date} is starting")

      begin
        raise IOError, "input flow <#{input_distribution.basename}> is missing" unless input_distribution.exist? #input

        tmp_distribution_count = Flow.new(TMP, "hourly-daily-distribution", input_distribution.label, input_distribution.date) #output

        distribution_per_day = ""
        i = 1
        day_save = ""

        p = ProgressBar.create(:title => "Building hourly daily distribution", :length => 180, :starting_at => 0, :total => input_distribution.count_lines(EOFLINE), :format => '%t, %c/%C, %a|%w|')
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
        @logger.an_event.debug e
        @logger.an_event.error("cannot build hourly daily distribution for <#{input_distribution.label}>")
      end
      @logger.an_event.info("Building hourly daily distribution for <#{input_distribution.label}> is over")
    end

    def Building_behaviour(input_behaviour)
      #pas de prise en compte du multi-volume car la requete ga limite le nombre de resultats
      @logger.an_event.info("Building behaviour for #{input_behaviour.label} for #{input_behaviour.date} is starting")
      begin
        raise IOError, "input flow <#{input_behaviour.basename}> is missing" unless input_behaviour.exist?

        tmp_behaviour = Flow.new(TMP, "behaviour", input_behaviour.label, input_behaviour.date) #output
        p = ProgressBar.create(:title => "Building behaviour", :length => 180, :starting_at => 0, :total => input_behaviour.count_lines(EOFLINE), :format => '%t, %c/%C, %a|%w|')
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
        @logger.an_event.debug e
        @logger.an_event.error("cannot build behaviour for <#{input_behaviour.label}>")
      end
      @logger.an_event.info("Building behaviour for <#{input_behaviour.label}> is over")
    end

  end

end


