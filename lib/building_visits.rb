#!/usr/bin/env ruby -w
# encoding: UTF-8

require File.dirname(__FILE__) + '/../lib/logging'
require 'socket'
#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------


module Building_visits
#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------
  INPUT = File.dirname(__FILE__) + "/../input/"
  OUTPUT = File.dirname(__FILE__) + "/../output/"
  TMP = File.dirname(__FILE__) + "/../tmp/"
  SEPARATOR="%SEP%"
  EOFLINE="%EOFL%"
  SEPARATOR2=";"
  SEPARATOR3=","
  SEPARATOR4="|"
  EOFLINE2 ="\n"
  LOG_FILE = File.dirname(__FILE__) + "/../log/" + File.basename(__FILE__, ".rb") + ".log"

#inputs

# local
  attr :matrix,
       :duration_pages,
       :visits,
       :matrix_file,
       :count_visits_by_hour,
       :planed_visits_by_hour_file

  class Page
    attr :id_uri,
         :delay_from_start,
         :hostname,
         :page_path,
         :title


    def initialize(id_page, duration)
      @id_uri = id_page.strip
      @delay_from_start = duration
    end

    def to_s(*a)
      page = "#{@id_uri}"
      page += "#{SEPARATOR4}#{@delay_from_start}" unless @delay_from_start.nil?
      page += "#{SEPARATOR4}#{@hostname}" unless @hostname.nil?
      page += "#{SEPARATOR4}#{@page_path}" unless @page_path.nil?
      page += "#{SEPARATOR4}#{@title}" unless @title.nil?
      page
    end


    def set_properties(pages_file)
      pages_file.rewind
      #p pages_file.lineno
      begin
        begin
          splitted_page = pages_file.readline(EOFLINE2).split(SEPARATOR2)
        end while @id_uri != splitted_page[0]
        @hostname = splitted_page[1].strip
        @page_path = splitted_page[2].strip
        @title = splitted_page[3].strip
      rescue Exception => e
        p "ERROR : #{e.message}=> id uri #{@id_uri} not found in pages_file"
        raise "errer"
      end
    end

    def to_json(*a)

    end
  end

  class Visit
    @@count_visit = 0

    attr :id_visit,
         :start_date_time,
         :account_ga,
         :return_visitor,
         :browser_version,
         :operating_system,
         :operating_system_version,
         :flash_version,
         :java_enabled,
         :screens_colors,
         :screen_resolution,
         :pages

    def initialize(first_page, duration)
      @@count_visit += 1
      @id_visit = @@count_visit
      splitted_page = first_page.split(SEPARATOR2)
      @referral_path = splitted_page[1].strip
      @source = splitted_page[2].strip
      @medium = splitted_page[3].strip
      @keyword = splitted_page[4].strip
      @pages = [Page.new(splitted_page[0], duration)]
    end

    def length()
      @pages.size
    end

    def bounce?()
      length == 1
    end

    def landing_page
      @pages[0].id_uri
    end

    def add_page(id_uri, duration)
      @pages << Page.new(id_uri, duration)
    end

    def to_s(*a)
      visit = "#{@id_visit}"
      visit += "#{SEPARATOR2}#{@start_date_time}" unless @start_date_time.nil?
      visit += "#{SEPARATOR2}#{@referral_path}" unless @referral_path.nil?
      visit += "#{SEPARATOR2}#{@source}" unless @source.nil?
      visit += "#{SEPARATOR2}#{@medium}" unless @medium.nil?
      visit += "#{SEPARATOR2}#{@keyword}" unless @keyword.nil?
      if !@pages.nil?
        pages = "#{SEPARATOR2}"
        @pages.map { |page| pages += "#{page.to_s}#{SEPARATOR3}" }
        pages = pages.chop if pages[pages.size - 1] == SEPARATOR3
        visit += pages
      end
      visit
    end


    def to_json(*a)

    end
  end

  class Planed_visit < Visit

    def initialize(visit, date, hour)
      splitted_visit = visit.split(SEPARATOR2)
      @id_visit = splitted_visit[0].strip
      new_date = Date.parse(date)

      @start_date_time = Time.new(new_date.year,
                                  new_date.month,
                                  new_date.day,
                                  hour.to_i,
                                  rand(60),
                                  0)
      @referral_path = splitted_visit[1].strip
      @source = splitted_visit[2].strip
      @medium = splitted_visit[3].strip
      @keyword = splitted_visit[4].strip
      @pages = []
      splitted_visit[5].strip.split(SEPARATOR3).each { |page|
        splitted_page = page.split(SEPARATOR4)
        id_uri = splitted_page[0].strip
        delay_from_start = splitted_page[1].strip
        @pages << Page.new(id_uri, delay_from_start)
      }
    end
  end

  class Final_visit < Planed_visit

    def initialize(visit, account_ga, return_visitor, pages_file)
      splitted_visit = visit.split(SEPARATOR2)

      @id_visit = splitted_visit[0].strip
      @start_date_time = splitted_visit[1].strip
      @referral_path = splitted_visit[2].strip
      @source = splitted_visit[3].strip
      @medium = splitted_visit[4].strip
      @keyword = splitted_visit[5].strip
      @pages = []
      splitted_visit[6].strip.split(SEPARATOR3).each { |page|
        splitted_page = page.split(SEPARATOR4)
        id_uri = splitted_page[0].strip
        delay_from_start = splitted_page[1].strip
        p = Page.new(id_uri, delay_from_start)
        p.set_properties(pages_file)
        @pages << p
      }
      @account_ga = account_ga
      @return_visitor = return_visitor
    end
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

  def Building_visits(label, date, count_visit,
      visit_bounce_rate,
      page_views_per_visit,
      avg_time_on_site,
      min_durations,
      min_pages)
    begin
      information("Building visits for #{label} is starting")
      Logging.send(LOG_FILE, Logger::DEBUG, "count_visit #{count_visit}")
      Logging.send(LOG_FILE, Logger::DEBUG, "visit_bounce_rate #{visit_bounce_rate}")
      Logging.send(LOG_FILE, Logger::DEBUG, "page_views_per_visit #{page_views_per_visit}")
      Logging.send(LOG_FILE, Logger::DEBUG, "avg_time_on_site #{avg_time_on_site}")
      Logging.send(LOG_FILE, Logger::DEBUG, "min_durations #{min_durations}")
      Logging.send(LOG_FILE, Logger::DEBUG, "min_pages #{min_pages}")

      count_pages = count_visit * page_views_per_visit
      count_durations = count_visit * avg_time_on_site
      @duration_pages = distributing(count_pages, count_durations, min_durations)
      @visits = []

      IO.foreach(TMP + "chosen_landing_pages-#{label}-#{date}.txt", EOFLINE2, encoding: "BOM|UTF-8:-") { |page|
        @visits << Visit.new(page.chop, @duration_pages.pop)
      }

      building_not_bounce_visit(label, date, visit_bounce_rate, count_visit, page_views_per_visit, min_pages)

      @visits_file = File.open(TMP + "visits-#{label}-#{date}.txt", "w:utf-8")
      @visits_file.sync = true
      @visits.each { |visit| @visits_file.write("#{visit.to_s}#{EOFLINE2}") }
      @visits_file.close

      information("Building visist for #{label} is over")
      execute_next_step("Building_planification", label, date)
    rescue Exception => e
      error(e.message)
    end
  end

#--------------------------------------------------------------------------------------------------------------
# Building_planification
#--------------------------------------------------------------------------------------------------------------
#
# --------------------------------------------------------------------------------------------------------------
  def Building_planification(label, date, hourly_distribution, count_visits)
    begin
      information("Building planification of visit for #{label} is starting")

      hourly_distribution = hourly_distribution.split(";")
      @count_visits_by_hour = []
      @planed_visits_by_hour_file = []
      rest_sum = 0
      hourly_distribution.each_index { |hour|
        @count_visits_by_hour << [hour, (hourly_distribution[hour].to_f * count_visits).divmod(100)[0]]
        rest_sum += (hourly_distribution[hour].to_f * count_visits).divmod(100)[1]
        @planed_visits_by_hour_file[hour] = File.open(TMP + "planed-visits-#{label}-#{date}-#{hour}.txt", "w:utf-8")
        @planed_visits_by_hour_file[hour].sync = true
      }
      @count_visits_by_hour[rand(23)][1] += (rest_sum/count_visits).to_i # permet d'eviter de perdre des visits lors de la division qd le reste est non nul => n'arrive pas si le nombre de viste est grand

      IO.foreach(TMP + "visits-#{label}-#{date}.txt", EOFLINE2, encoding: "BOM|UTF-8:-") { |visit|
        hour = chose_an_hour()
        v = Planed_visit.new(visit, date, hour)
        @planed_visits_by_hour_file[hour].write("#{v.to_s}#{EOFLINE2}")
      }

      24.times { |hour| @planed_visits_by_hour_file[hour].close }
      information("Building planification of visit for #{label} is over")
      execute_next_step("Extending_visits", label, date)
    rescue Exception => e
      error(e.message)
    end
  end

#--------------------------------------------------------------------------------------------------------------
# Extending_visits
#--------------------------------------------------------------------------------------------------------------
#
# --------------------------------------------------------------------------------------------------------------
  def Extending_visits(label, date, count_visit, account_ga, return_visitor_rate)
    begin
      information("Extending visits for #{label} is starting")

      24.times { |hour|
        pages_file = File.open(TMP + "pages-#{label}-#{date}.txt", "r:utf-8")
        final_visits_by_hour_file = File.open(TMP + "final-visits-#{label}-#{date}-#{hour}.txt", "w:utf-8")
        final_visits_by_hour_file.sync = true
        IO.foreach(TMP + "planed-visits-#{label}-#{date}-#{hour}.txt", EOFLINE2, encoding: "BOM|UTF-8:-") { |visit|
          return_visitor = true
          v = Final_visit.new(visit, account_ga, return_visitor, pages_file)

          final_visits_by_hour_file.write("#{v.to_s}#{EOFLINE2}")
        } unless File.zero?(TMP + "planed-visits-#{label}-#{date}-#{hour}.txt")
      }

      information("Extending visits for #{label} is over")
      execute_next_step("Publishing_visits", label, date)
    rescue Exception => e
      error(e.message)
    end
  end

#--------------------------------------------------------------------------------------------------------------
# Publishing_visits
#--------------------------------------------------------------------------------------------------------------
#
# --------------------------------------------------------------------------------------------------------------
  def Publishing_visits(label, date)
    begin
      information("Publishing visits for #{label} is starting")

      information("Publishing visits for #{label} is over")
    rescue Exception => e
      error(e.message)
    end
  end

#--------------------------------------------------------------------------------------------------------------
# private
#--------------------------------------------------------------------------------------------------------------
  def building_not_bounce_visit(label, date, visit_bounce_rate, count_visit, page_views_per_visit, min_pages)
    begin
      information("Building not bounce visit for #{label} is starting")
      count_bounce_visit = (visit_bounce_rate * count_visit/100).to_i
      count_not_bounce_visit = count_visit - count_bounce_visit
      count_pages_bounce_visit = count_bounce_visit
      count_pages_not_bounce_visit = count_visit * page_views_per_visit - count_pages_bounce_visit
      count_pages_per_visits = distributing(count_not_bounce_visit, count_pages_not_bounce_visit, min_pages)
      Logging.send(LOG_FILE, Logger::DEBUG, "count_bounce_visit #{count_bounce_visit}")
      Logging.send(LOG_FILE, Logger::DEBUG, "count_not_bounce_visit #{count_not_bounce_visit}")
      Logging.send(LOG_FILE, Logger::DEBUG, "count_pages_not_bounce_visit #{count_pages_not_bounce_visit}")
      Logging.send(LOG_FILE, Logger::DEBUG, "count_pages_per_visits #{count_pages_per_visits}")

      @matrix_file = File.open(TMP + "matrix-#{label}-#{date}.txt", "r:utf-8")
      count_not_bounce_visit.times { |visit|
        begin
          v = @visits.shuffle![0]
        end while !v.bounce?

        Logging.send(LOG_FILE, Logger::DEBUG, "Exploring visit #{v} for #{label}")
        Logging.send(LOG_FILE, Logger::DEBUG, "with count_page : #{count_pages_per_visits[visit]}")
        explore_visit_from v, v.landing_page, count_pages_per_visits[visit]
      }
      @matrix_file.close
      information("Building not bounce visit for #{label} is over")
    rescue Exception => e
      error(e.msg)
    end
  end


#------------------------------------------------------------------------------------------------------------------
# children
#------------------------------------------------------------------------------------------------------------------
# ensemble des pages sur lesquelles pointe la page courante
# les liens sont dans le fichier matrix.
# quand un lien a été identifié alors il est chargé en mémoire pour accéler, au cas où on repasse par là
#------------------------------------------------------------------------------------------------------------------
  def children(pt)
    @matrix = {} if @matrix.nil?
    if @matrix[pt].nil?
      @matrix[pt] = []
      @matrix_file.rewind
      (pt.to_i - 1).times { @matrix_file.readline(EOFLINE2) }
    @matrix_file.readline(EOFLINE2).split(SEPARATOR2)[1].strip.split(SEPARATOR3).each { |page| @matrix[pt] << page.strip }
    end
    Array.new(@matrix[pt])
  end

#------------------------------------------------------------------------------------------------------------------
# leaf?
#------------------------------------------------------------------------------------------------------------------
# la page contient elle des liens
#------------------------------------------------------------------------------------------------------------------
#la page pointe elle sur d'autre page (feuille du graphe)
  def leaf?(pt)
    children(pt).size == 0
  end

#------------------------------------------------------------------------------------------------------------------
# explore_visit_from
#------------------------------------------------------------------------------------------------------------------
# construit la visite en respectant le nombre de pages comme objectif
#------------------------------------------------------------------------------------------------------------------
  def explore_visit_from(visit, start, count_visit, stack=nil)

    stack << start unless stack.nil?
    stack = [start] if stack.nil?

    if !leaf?(start) and # on continue d'explorer si il y a un enfant, sinon tant pis la visite n'aura pas la bonnne longeur
        count_visit > 1
      children = children(start)
      children.each { |child|
        if child == start
          children.delete(child)
        end
      }
      child = children.shuffle![0]
      information("start #{start}") if child == ""
      visit.add_page(child, @duration_pages.pop)
      explore_visit_from(visit,
                         child,
                         count_visit-=1,
                         stack)
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
    res
  end

  def chose_an_hour()
    @count_visits_by_hour.delete_if { |value| value[1] == 0 }

    choice = rand(@count_visits_by_hour.size - 1)
    hour = @count_visits_by_hour[choice][0]
    @count_visits_by_hour[choice][1] -= 1

    hour
  end

  def information(msg)
    Logging.send(LOG_FILE, Logger::INFO, msg)
    p "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} => #{msg}"
  end

  def error(msg)
    Logging.send(LOG_FILE, Logger::ERROR, msg)
    p "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} ERROR => #{msg}"
  end

  def execute_next_step(cmd, label, date)
    s = TCPSocket.new 'localhost', $listening_port
    s.puts JSON.generate({"cmd" => cmd, "label" => label, "date_building" => date})
    s.close
  end

  def min(a, b)
    a < b ? a : b
  end

# public
  module_function :Building_planification
  module_function :Building_visits
  module_function :Extending_visits
  module_function :Publishing_visits
# private
  module_function :chose_an_hour
  module_function :building_not_bounce_visit
  module_function :unite
  module_function :distributing
  module_function :explore_visit_from
  module_function :children
  module_function :leaf?
  module_function :execute_next_step
  module_function :information
  module_function :error
  module_function :min
end