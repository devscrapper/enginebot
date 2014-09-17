#!/usr/bin/env ruby -w
# encoding: UTF-8
require_relative '../../lib/logging'
require_relative '../../model/tasking/task'
require_relative 'visit'
require_relative 'page'
require_relative 'reporting'
require 'ruby-progressbar'
#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------


module Building
  #TODO calculer visit[:referrer][:durations] pour organic en fonction des parametres fournis par statupweb
  #TODO calculer visit[:referrer][:duration] pour referral en fonction des parametres fournis par statupweb
  #TODO calculer visit[:advertising][:advertser][durations] et [around] en fonction des parametres fournis par statupweb
  #TODO calculer visit[:landing][duration]
  #TODO calculer visit[:durations]
  PROGRESS_BAR_SIZE = 180
  class Visits
    class VisitsException < StandardError
    end

    include Tasking
#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------
    OUTPUT = File.dirname(__FILE__) + "/../../output"
    TMP = File.dirname(__FILE__) + "/../../tmp"
    SEPARATOR1=";"
    SEPARATOR2="|"
    SEPARATOR3=","
    EOFLINE ="\n"

# local
    attr :matrix,
         :duration_pages,
         :visits,
         :children,
         :matrix_file,
         :count_visits_by_hour,
         :planed_visits_by_hour_file,
         :label,
         :date_building

    def initialize(label, date_building)
      @label = label
      @date_building = date_building
      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
    end

#--------------------------------------------------------------------------------------------------------------
# Building_visits
#--------------------------------------------------------------------------------------------------------------
# Construit les visites en fonction des proprietes de l'objectif du jour :
# le taux de visite rebond
# le nombre de page par visite
# le temps moyen d'une visite sur le site
# la duree minimale d'exposition d'une page
# le nombre de page minimal de page par visite
# --------------------------------------------------------------------------------------------------------------


    def Building_visits(count_visit,
        visit_bounce_rate,
        page_views_per_visit,
        avg_time_on_site,
        min_durations,
        min_pages)
      @logger.an_event.info("Building visits for #{@label} for #{@date_building} is starting")
      begin

        @logger.an_event.debug("count_visit #{count_visit}")
        @logger.an_event.debug("visit_bounce_rate #{visit_bounce_rate}")
        @logger.an_event.debug("page_views_per_visit #{page_views_per_visit}")
        @logger.an_event.debug("avg_time_on_site #{avg_time_on_site}")
        @logger.an_event.debug("min_durations #{min_durations}")
        @logger.an_event.debug("min_pages #{min_pages}")


        reporting = Reporting.new(@label, @date_building, @logger)
        reporting.visit_obj(count_visit, visit_bounce_rate, page_views_per_visit, avg_time_on_site, min_durations, min_pages)
        reporting.to_file

        @matrix_file = Flow.new(TMP, "matrix", @label, @date_building).last #input utilisé par building_not_bounce_visit
        raise IOError, "input matrix file for #{@label} is missing" if @matrix_file.nil?
        chosen_landing_pages_file = Flow.new(TMP, "chosen-landing-pages", @label, @date_building) #input
        raise IOError, "tmp flow <#{chosen_landing_pages_file.basename}> is missing" unless chosen_landing_pages_file.exist?
        count_chosen_landing_page = chosen_landing_pages_file.count_lines(EOFLINE)
        raise ArgumentError, "because not enough count landing page <#{count_chosen_landing_page}> for <#{count_visit}> visits" if count_chosen_landing_page < count_visit
        @logger.an_event.warn "too much count landing page <#{count_chosen_landing_page}> for <#{count_visit}> visits" if count_chosen_landing_page > count_visit
        count_pages = (count_visit * page_views_per_visit).to_i
        count_durations = (count_visit * avg_time_on_site).to_i
        @duration_pages = distributing(count_pages, count_durations, min_durations)
                                                                            #TODO : valider que la distribution de duration pour les pages de la visite, positionne comme première valeur, la valeur minimale afin que la landing page soit déclencher en premier
                                                                            #TODO : controler commen cela est fait  : les durée associé aux page sont elle
                                                                            # TODO en delta par rapport à la précédent => il n'est pas nécessaire que les durées soit croissante
                                                                            # TODO par rapport à la visit : il faut que les durée soit croissante pour la llstye depage de la visit
        min_duration_idx = @duration_pages.index(@duration_pages.min)
        if min_duration_idx > 0
          min_duration = @duration_pages[min_duration_idx]
          @duration_pages.delete_at(min_duration_idx)
          @duration_pages = [min_duration] + @duration_pages
        end

        @visits = []
        p = ProgressBar.create(:title => "Loading chosen landing pages", :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => count_visit, :format => '%t, %c/%C, %a|%w|')
        chosen_landing_pages_file.foreach(EOFLINE) { |page|
          @logger.an_event.debug("page  #{page}")
          @visits << Visit.new(page.chop, @duration_pages.pop)
          p.increment
        }

        building_not_bounce_visit(visit_bounce_rate, count_visit, page_views_per_visit, min_pages)

        @visits_file = Flow.new(TMP, "visits", @label, @date_building) #output
        p = ProgressBar.create(:title => "Saving visits", :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => count_visit, :format => '%t, %c/%C, %a|%w|')
        @visits.each { |visit| @visits_file.write("#{visit.to_s}#{EOFLINE}"); p.increment }
        @visits_file.close
        @matrix_file.close
        @visits_file.archive_previous
        Task.new("Building_planification", {"label" => @label, "date_building" => @date_building}).execute()
      rescue Exception => e
        @logger.an_event.error "cannot build visits for #{@label} for #{@date_building}"
        @logger.an_event.debug e
      end
      @logger.an_event.info("Building visits for #{@label} is over")
    end

#--------------------------------------------------------------------------------------------------------------
# Building_planification
#--------------------------------------------------------------------------------------------------------------
#
# --------------------------------------------------------------------------------------------------------------
    def Building_planification(hourly_distribution, count_visits)
      @logger.an_event.info("Building planification of visit for #{@label}  for #{@date_building} is starting")
      begin
        reporting = Reporting.new(@label, @date_building, @logger)
        reporting.planification_obj(hourly_distribution)
        reporting.to_file

        visits_tmp = Flow.new(TMP, "visits", @label, @date_building)
        raise IOError, "tmp flow <#{visits_tmp.basename}> is missing" unless visits_tmp.exist?
        count_visits_of_day = 0
        hourly_distribution.split(SEPARATOR2).each { |count_visit_per_hour| count_visits_of_day += count_visit_per_hour.to_i }
        raise ArgumentError, "sum of hourly distribution of visits is different count visits" unless count_visits_of_day == count_visits

        @logger.an_event.debug "param count_visits #{count_visits}"
        @planed_visits_by_hour_file = []
        @count_visits_by_hour =[]
        hour = 0
        hourly_distribution.split(SEPARATOR2).each { |count_visits_per_hour|
          @count_visits_by_hour[hour] = [hour, count_visits_per_hour.to_i]
          hour += 1
        }
        @logger.an_event.debug "@count_visits_by_hour #{@count_visits_by_hour}"
        hour = 0
        count_visits_of_day_origin = 0
        #initialisation des fichier à empty car il se peut que pour une une heure il n y ait pas de visit,
        # il faut qd même crer un fichier vide pour eviter que l'extending échoue et
        # cela eviter de se poser des questions sur l'absence de fichier
        24.times { |anhour| Flow.new(TMP, "planed-visits", @label, @date_building, anhour + 1).empty }

        @count_visits_by_hour.each { |count_visit_per_hour| count_visits_of_day_origin += count_visit_per_hour[1].to_i }
        @logger.an_event.debug "@count_visits_by_hour #{@count_visits_by_hour}"
        @logger.an_event.debug "@count_visits_by_hour.size #{@count_visits_by_hour.size}"
        @logger.an_event.debug "total visit of @count_visits_by_hour #{count_visits_of_day_origin}"


        @count_visits_by_hour.size.times { |anhour|
          @planed_visits_by_hour_file[anhour] = Flow.new(TMP, "planed-visits", @label, @date_building, anhour + 1)
          @logger.an_event.debug @planed_visits_by_hour_file[anhour].basename
        }


        p = ProgressBar.create(:title => "Saving planed visits", :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => count_visits, :format => '%t, %c/%C, %a|%w|')

        visits_tmp.foreach(EOFLINE) { |visit|
          @logger.an_event.debug "@count_visits_by_hour #{@count_visits_by_hour}"
          hour = chose_an_hour()
          v = Planed_visit.new(visit, @date_building, hour)
          @logger.an_event.debug hour
          @logger.an_event.debug @planed_visits_by_hour_file[hour].basename
          @planed_visits_by_hour_file[hour].write("#{v.to_s}#{EOFLINE}")
          p.increment
        }

        24.times { |anhour| @planed_visits_by_hour_file[anhour].close }


        Task.new("Extending_visits", {"label" => @label, "date_building" => @date_building}).execute()
      rescue Exception => e
        @logger.an_event.debug e
        @logger.an_event.error "cannot plan visits"
      end
      @logger.an_event.info("Building planification of visit for #{@label} is over")
    end

#--------------------------------------------------------------------------------------------------------------
# Extending_visits
#--------------------------------------------------------------------------------------------------------------
#
# --------------------------------------------------------------------------------------------------------------
    def Extending_visits(count_visit,
        return_visitor_rate,
        advertising_percent,
        advertisers)
      @logger.an_event.info("Extending visits for #{@label}  for #{@date_building} is starting")
      @logger.an_event.debug("advertising_percent #{advertising_percent}")
      @logger.an_event.debug("advertisers #{advertisers}")
      begin
        reporting = Reporting.new(@label, @date_building, @logger)
        reporting.return_visitor_obj(return_visitor_rate)
        reporting.advertising_obj(advertising_percent, advertisers)
        reporting.to_file

        device_platform_file = Flow.new(TMP, "chosen-device-platform", @label, @date_building)
        raise IOError, "tmp flow <#{device_platform_file.basename}>  is missing" unless device_platform_file.exist?
        count_device_platform = device_platform_file.count_lines(EOFLINE)
        raise ArgumentError, "not enough count device platform <#{count_device_platform}> for <#{count_visit}> visits" if count_device_platform < count_visit
        @logger.an_event.warn "too much count device platform <#{count_device_platform}> for <#{count_visit}>  visits" if count_device_platform > count_visit
        pages_file = Flow.new(TMP, "pages", @label, @date_building).last #input
        raise IOError, "tmp flow pages for <#{@label}> for <#{@date_building}> is missing" if  pages_file.nil?

        #on tri le fichier de page sur le id pour accelerer la recherche de page qui s'appuie sur une dichotomie
        pages_file.sort { |line| [line.split(SEPARATOR1)[0]] }
        #on charge en memoire le fichier
        pages = pages_file.load_to_array(EOFLINE)

        #initialisation des fichier à empty car il se peut que pour une une heure il n y ait pas de visit,
        # et que le fichier soit vide.
        # il faut qd même crer un fichier final- vide pour eviter que le publishing échoue et
        # cela eviter de se poser des questions sur l'absence de fichier
        24.times { |anhour| Flow.new(TMP, "final-visits", @label, @date_building, anhour + 1).empty }

        device_platforms = device_platform_file.readlines(EOFLINE).shuffle
        @logger.an_event.debug device_platforms
        return_visitors = Array.new(count_visit, false)
        return_visitors.fill(true, 0..(count_visit * return_visitor_rate / 100).to_i).shuffle!

        adverts = Array.new(count_visit, "none")
        adverts.fill(advertisers.shuffle![0], 0..(count_visit * advertising_percent / 100).to_i).shuffle!

        p = ProgressBar.create(:title => "Saving Final visits", :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => count_visit, :format => '%t, %c/%C, %a|%w|')

        24.times { |hour|
          final_visits_by_hour_file = Flow.new(TMP, "final-visits", @label, @date_building, hour + 1) #output
          planed_visits_file = Flow.new(TMP, "planed-visits", @label, @date_building, hour + 1) #input
          raise IOError, "tmp flow <#{planed_visits_file.basename}> is missing" unless planed_visits_file.exist?
          planed_visits_file.foreach(EOFLINE) { |visit|
            return_visitor = return_visitors.shift
            advert = adverts.shift
            begin
              v = Final_visit.new(visit, return_visitor, advert, pages, device_platforms.shift)
              final_visits_by_hour_file.write("#{v.to_s}#{EOFLINE}")
            rescue Exception => e
              @logger.an_event.debug visit
              @logger.an_event.debug e
              raise VisitsException, "cannot create or save final visit"
            end
            p.increment
          } unless planed_visits_file.zero?
          planed_visits_file.close
          final_visits_by_hour_file.close
          planed_visits_file.archive
        }
        device_platform_file.close
        pages_file.close

        Task.new("Reporting_visits", {"label" => @label, "date_building" => @date_building}).execute()
      rescue Exception => e
        @logger.an_event.debug e
        @logger.an_event.error("cannot extend visits for #{@label}")
      end
      @logger.an_event.info("Extending visits for #{@label} is over")
    end

    #--------------------------------------------------------------------------------------------------------------
    # Reporting_visits
    #--------------------------------------------------------------------------------------------------------------
    #
    # --------------------------------------------------------------------------------------------------------------
    def Reporting_visits
      @logger.an_event.info("Reporting visits for #{@label} for #{@date_building} is starting")
      start_time = Time.now
      begin
        reporting = Reporting.new(@label, @date_building, @logger)
        p = ProgressBar.create(:title => "Reporting visits", :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => 24, :format => '%t, %c/%C, %a|%w|')

        24.times { |hour|
          final_visits_by_hour_file = Flow.new(TMP, "final-visits", @label, @date_building, hour + 1) #input

          raise IOError, "tmp flow <#{final_visits_by_hour_file.basename}> is missing" unless final_visits_by_hour_file.exist?

          final_visits_by_hour_file.foreach(EOFLINE) { |visit|
            begin
              reporting.visit(Published_visit.new(visit))
            rescue Exception => e
              @logger.an_event.debug visit.to_s
              @logger.an_event.error "cannot report visit : #{e.message}"
            end

          } unless final_visits_by_hour_file.zero?
          final_visits_by_hour_file.close
          p.increment
        }

        reporting.to_file
        reporting.to_mail
        reporting.archive
      rescue Exception => e
        @logger.an_event.error("Reporting visits for #{@label} for #{@date_building} : #{e.message}")
      ensure
        @logger.an_event.info("Reporting visits for #{@label} for #{@date_building} is over (#{Time.now - start_time})")
      end
    end

    #--------------------------------------------------------------------------------------------------------------
    # Publishing_visits
    #--------------------------------------------------------------------------------------------------------------
    #
    # --------------------------------------------------------------------------------------------------------------
    def Publishing_visits_by_hour(day=nil)
      # le déclenchement de la publication est réalisée 2 heures avant l'heure d'exécution proprement dite des visits
      # de 22:00 à j-1 pour j à 00:00
      # à 
      # de 21:00 à j pour j à 23:00
      # ce parametrage est réalisé lors de la transformation des objectives en events dans le fichier model/planning/object2event/objective.rb
      # cela entraine qu'il faut ajouter 2 heures pour le nom du output flow
      #
      # autre point : 
      # les flow final_visit sont suffixés par l'heure déclenchement des visits de 1 à 24 hour.
      # cela entraine qu'il faut ajouter 1 heure à l'heure courante pour récupérer le bon volume du flow final_visit.
      # de 22:00 à j-1 pour j à 00:00 => final_visits_J_1.txt & publishing_visits_J_1.json
      # de 23:00 à j-1 pour j à 01:00 => final_visits_J_2.txt & publishing_visits_J_2.json
      # de 0:00 à j pour j à 02:00 => final_visits_J_3.txt & publishing_visits_J_3.json
      # de 1:00 à j pour j à 03:00 => final_visits_J_4.txt & publishing_visits_J_4.json
      # à 
      # de 21:00 à j pour j à 23:00   => final_visits_J_24.txt & publishing_visits_J_24.json
      #---------------------------
      # si day <> de nil alors on force le jour de planification pour faciliter les tests.

      current_time = Time.now
      an_hour = 60 * 60
      selected_time = current_time + (2 * an_hour)
      hour = selected_time.hour + 1 #hour est seulement utilisé pour construire le nom du flow.
      @logger.an_event.debug "current time <#{current_time}>, selected day <#{@date_building}>, selected hour <#{hour}>"
      @logger.an_event.info("Publishing at #{current_time} visits for #{@label} for #{@date_building}:#{hour}:00 is starting")
      begin
        final_visits_file = Flow.new(TMP, "final-visits", @label, @date_building, hour) #input
        raise IOError, "tmp flow <#{final_visits_file.basename}> is missing" unless final_visits_file.exist?

        p = ProgressBar.create(:title => "publish #{final_visits_file.basename}", :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => final_visits_file.count_lines(EOFLINE), :format => '%t, %c/%C, %a|%w|')
        final_visits_file.foreach(EOFLINE) { |visit|
          v = Published_visit.new(visit)
          if day.nil?
            start_date_time = v.start_date_time.strftime("%Y-%m-%d-%H-%M-%S")
          else
            start_date_time = Time.new(day.year, day.month, day.day, v.start_date_time.hour, v.start_date_time.min, v.start_date_time.sec).strftime("%Y-%m-%d-%H-%M-%S")
          end
          published_visits_to_yaml_file = Flow.new(TMP, "#{v.operating_system}-#{v.operating_system_version}", @label, start_date_time, v.id_visit, ".yml")
          published_visits_to_yaml_file.write(v.generate_output(@label).to_yaml)
          published_visits_to_yaml_file.close
          p.increment
        }
        final_visits_file.archive
      rescue Exception => e
        @logger.an_event.debug e
        @logger.an_event.error "cannot publish visits  at #{hour} hour for #{@label}"
      end
      @logger.an_event.info("Publishing  at #{current_time} visits for #{@label} for #{@date_building}:#{hour}:00 is over")
    end

#--------------------------------------------------------------------------------------------------------------
# private
#--------------------------------------------------------------------------------------------------------------
    def building_not_bounce_visit(visit_bounce_rate, count_visit, page_views_per_visit, min_pages)
      @logger.an_event.info("Building not bounce visit for #{@label} is starting")
      begin
        count_bounce_visit = (visit_bounce_rate * count_visit/100).to_i
        count_not_bounce_visit = count_visit - count_bounce_visit
        count_pages_bounce_visit = count_bounce_visit
        count_pages_not_bounce_visit = (count_visit * page_views_per_visit).to_i - count_pages_bounce_visit
        count_pages_per_visits = distributing(count_not_bounce_visit, count_pages_not_bounce_visit, min_pages)
        @logger.an_event.debug("count_bounce_visit #{count_bounce_visit}")
        @logger.an_event.debug("count_not_bounce_visit #{count_not_bounce_visit}")
        @logger.an_event.debug("count_pages_not_bounce_visit #{count_pages_not_bounce_visit}")
        @logger.an_event.debug("count_pages_per_visits #{count_pages_per_visits}")

        @children = @matrix_file.load_to_hash(EOFLINE) { |line|
          arr = line.split(SEPARATOR1)
          key = arr[0]
          res = {}
          if arr[1].nil?
            # la page est une feuille, n'a donc pas de lien vers d'autre page => on ne la charge pas en mémoire
            # c'est pourquoi la methode leaf? teste si la page est présente dans le hash en mémoire et pas le nombre de page associé
          else
            value = arr[1].split(SEPARATOR3)
            value.compact! unless value.delete(key).nil? # suppression de la clé ie la page origine pour eliminer les cycles
            res = {key => value}
          end
          res
        }

        p = ProgressBar.create(:title => "Building not bounce visits", :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => count_not_bounce_visit, :format => '%t, %c/%C, %a|%w|')
        count_not_bounce_visit.times { |visit|
          begin
            v = @visits.shuffle![0]
            @logger.an_event.debug("prospect #{v} for #{@label}")
          end while !v.bounce?

          @logger.an_event.debug("Exploring visit #{v} for #{@label}")
          @logger.an_event.debug("with count_page : #{count_pages_per_visits[visit]}")
          explore_visit_from v, v.landing_page, count_pages_per_visits[visit]
          p.increment
        }

      rescue Exception => e
        @logger.an_event.debug e
        raise "cannot build not bounce visit"
      end
      @logger.an_event.info("Building not bounce visit for #{@label} is starting")
    end


#------------------------------------------------------------------------------------------------------------------
# children
#------------------------------------------------------------------------------------------------------------------
# ensemble des pages sur lesquelles pointe la page courante
# les liens sont dans le fichier matrix.
# quand un lien a été identifié alors il est chargé en mémoire pour accéler, au cas où on repasse par là
#------------------------------------------------------------------------------------------------------------------
# no more use since v0.29 which load in memory matrix file
#------------------------------------------------------------------------------------------------------------------
#    def children(pt)
#      @matrix = {} if @matrix.nil?
#      if @matrix[pt].nil?
#        begin
#          @matrix[pt] = []
#          @matrix_file.rewind
#          (pt.to_i - 1).times { @matrix_file.readline(EOFLINE) }
#          line = @matrix_file.readline(EOFLINE)
#          children = line.split(SEPARATOR1)[1]
#          children.strip.split(SEPARATOR3).each { |page| @matrix[pt] << page.strip }
#        rescue Exception => e
#          @logger.an_event.error "cannot calculate children of #{pt} for #{@label} at #{@date_building}"
#          @logger.an_event.debug line
#          @logger.an_event.debug children
#          @logger.an_event.debug e
#        end
#      end
#      Array.new(@matrix[pt])
#    end

#------------------------------------------------------------------------------------------------------------------
# leaf?
#------------------------------------------------------------------------------------------------------------------
# la page contient elle des liens
#------------------------------------------------------------------------------------------------------------------
#la page pointe elle sur d'autre page (feuille du graphe)
    def leaf?(pt)
      #children(pt).size == 0
      @children[pt].nil?
    end

#------------------------------------------------------------------------------------------------------------------
# explore_visit_from
#------------------------------------------------------------------------------------------------------------------
# construit la visite en respectant le nombre de pages comme objectif
#------------------------------------------------------------------------------------------------------------------
    def explore_visit_from(visit, start, count_visit, stack=nil)
      stack << start unless stack.nil?
      stack = [start] if stack.nil?

      if !leaf?(start) and # on continue d'explorer si il y a un enfant, sinon tant pis la visite n'aura pas la bonnne longueur
          count_visit > 1
        #children = children(start)
        child = @children[start].shuffle![0]
        @logger.an_event.fatal("start #{start}") if child == "" #ne doit jamais arrivé
        visit.add_page(child, @duration_pages.pop)
        explore_visit_from(visit,
                           child,
                           count_visit-=1,
                           stack)
      else
        #@logger.an_event.info("start #{start} is leaf? #{leaf?(start)} and count_visit = #{count_visit}")
      end
    end

    def unite(i, count=0)
      if i < 10
        count
      else
        unite(i.divmod(10)[0], count+1)
      end
    end

    def distributing(into, values, min_values_per_into)
      #p into
      #p values
      @logger.an_event.info("distribution is starting for #{@label} for #{@date_building}")
      values_per_into = (values/into).to_i
      max_values_per_into = 2 * values_per_into - min_values_per_into
      res = Array.new(into, values_per_into)

      values.modulo(into).times { |i| res[i]+=1 } #au cas ou la div est un reste > 0 alors on perd des pages donc on les repartit n'importe ou.

      # si le value par into est egal à 2 ou
      # si le nombre de into <= à 2 alors il est impossible de calculer une distribution
      # alors on retourne un ensemble de into ayant un nombre de value egal à 2
      if values_per_into > min_values_per_into and
          into > 2
        plus = 0
        moins = 0

        (10 ** (unite(into) + 4)).times {
          ok = false
          while !ok
            plus = rand(res.size-1)
            moins = rand(res.size-1)
            if plus != moins and res[plus] < max_values_per_into and res[moins] > min_values_per_into
              ok = true
            end
          end
          res[plus] += 1
          res[moins] -= 1

        }
      end
      @logger.an_event.info("distribution for #{@label} for #{@date_building} is over")
      res
    end

    def chose_an_hour
      @count_visits_by_hour.delete_if { |value| value[1] == 0 }
      @logger.an_event.debug "@count_visits_by_hour: #{@count_visits_by_hour}"
      @logger.an_event.debug "@count_visits_by_hour.size: #{@count_visits_by_hour.size}"
      hour = rand(@count_visits_by_hour.size - 1).to_i
      @logger.an_event.debug "hour selected: #{hour}/#{@count_visits_by_hour[hour][0]}"
      @count_visits_by_hour[hour][1] -= 1
      @logger.an_event.debug "@count_visits_by_hour[#{@count_visits_by_hour[hour][0]}]: #{@count_visits_by_hour[hour][1]}"
      @count_visits_by_hour[hour][0]
    end


    def min(a, b)
      a < b ? a : b
    end


  end
end
