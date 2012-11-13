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
       :matrix_file

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

    def to_json(*a)

    end
  end

  class Visit
    @@count_visit = 0

    attr :id_visit,
         :referral_path,
         :source,
         :medium,
         :keyword,
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
      visit << "#{EOFLINE2}"
      visit
    end

    def to_json(*a)

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

    information("Building visit for #{label} is starting")
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
    @visits.each { |visit| @visits_file.write(visit.to_s) }
    @visits_file.close

    information("Building visit for #{label} is over")
    execute_next_step("Distributing_visits", label, date)
  end
  #--------------------------------------------------------------------------------------------------------------
  # Distributing_visits
  #--------------------------------------------------------------------------------------------------------------
  #
  # --------------------------------------------------------------------------------------------------------------
  def Distributing_visits(label, date, hourly_distribution)
    @log_file = File.dirname(__FILE__) + "/../log/" + File.basename(__FILE__, ".rb") + ".log"
    Logging.send(@log_file, Logger::INFO, "distributing visit is starting #{label}")
    p "distributing visit is starting #{label}"
    data = File.open(OUTPUT + "visits-#{label}-#{date}.txt", "r:utf-8").read
    chosen_landing_pages = {}

    population = data.split(EOFL2)
    hourly_distribution = hourly_distribution.split(";")
    p "distribution :#{hourly_distribution}"
    p "population #{population}"
    count_population = population.size
    visits_file = File.open(OUTPUT + "visits-hourly-distributed-#{label}-#{date}.txt", "w:utf-8")
    visits_file.sync = true

    distribution = Array.new(24, [])
    indice_max = max = 0
    hourly_distribution.each_index { |hour|
      count_population_by_hour = (hourly_distribution[hour].to_f * count_population).divmod(100)[0]
      while count_population_by_hour > 0
        people = population[rand(population.size - 1)]
        population.delete_at(population.index(people))
        population.compact!
        distribution[hour] << people
        if distribution[hour].size > max
          max = distribution[hour].size
          indice_max = hour
        end
        count_population_by_hour -= 1
      end
      visits_file.write("#{distribution[hour]}\n")
    }
    p "distributing visit is over #{label}"
    Logging.send(@log_file, Logger::INFO, "distributing visit is over #{label}")
  end

  #--------------------------------------------------------------------------------------------------------------
  # private
  #--------------------------------------------------------------------------------------------------------------
  def building_not_bounce_visit(label, date, visit_bounce_rate, count_visit, page_views_per_visit, min_pages)
    information("Building not bounce visit for #{label}")
    count_bounce_visit = (visit_bounce_rate * count_visit/100).to_i
    count_not_bounce_visit = count_visit - count_bounce_visit
    count_pages_bounce_visit = count_bounce_visit
    count_pages_not_bounce_visit = count_visit * page_views_per_visit - count_pages_bounce_visit
    count_pages_per_visits = distributing(count_not_bounce_visit, count_pages_not_bounce_visit, min_pages)
    @matrix_file = File.open(TMP + "matrix-#{label}-#{date}.txt", "r:utf-8")
    count_not_bounce_visit.times { |visit|
      begin
        v = @visits.shuffle![0]
      end while !v.bounce?

      Logging.send(LOG_FILE, Logger::DEBUG, "Exploring visit #{v.to_s} for #{label}")
      Logging.send(LOG_FILE, Logger::DEBUG, "with count_page : #{count_pages_per_visits[visit]}")

      information ("Exploring visit with #{count_pages_per_visits[visit]} pages from landing page #{v.landing_page} for #{label}")
      explore_visit_from v, v.landing_page, count_pages_per_visits[visit]
    }
    @matrix_file.close
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
      @matrix_file.rewind
      (pt.to_i - 1).times { @matrix_file.readline(EOFLINE2) }
      @matrix[pt] = []
      @matrix_file.readline(EOFLINE2).split(SEPARATOR2)[1].split(SEPARATOR3).each { |page| @matrix[pt] << page.strip }
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

  def information(msg)
    Logging.send(LOG_FILE, Logger::INFO, msg)
    p "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} => #{msg}"
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
  module_function :Distributing_visits
  module_function :Building_visits

  # private
  module_function :building_not_bounce_visit
  module_function :unite
  module_function :distributing
  module_function :explore_visit_from
  module_function :children
  module_function :leaf?
  module_function :execute_next_step
  module_function :information
  module_function :min
end