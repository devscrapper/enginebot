#!/usr/bin/env ruby -w
# encoding: UTF-8

require File.dirname(__FILE__) + '/../lib/logging'
require 'socket'
require 'ruby-progressbar'
#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------



module Building_inputs
#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------
  INPUT = File.dirname(__FILE__) + "/../input/"
  TMP = File.dirname(__FILE__) + "/../tmp/"
  SEPARATOR="%SEP%"
  EOFLINE="%EOFL%"
  SEPARATOR2=";"
  EOFLINE2 ="\n"
  LOG_FILE = File.dirname(__FILE__) + "/../log/" + File.basename(__FILE__, ".rb") + ".log"
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

    def set_id_uri(id_pages_file)
      @id_uri = NOT_FOUND
      IO.foreach(id_pages_file, EOFLINE2, encoding: "BOM|UTF-8:-") { |page|
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
  end
#inputs

# local


  def Building_matrix_and_pages(label, date)
    information("Building matrix and page for #{label} is starting")
    matrix_file = File.open(TMP + "matrix-#{label}-#{date}.txt", "w:utf-8")
    matrix_file.sync = true
    pages_file = File.open(TMP + "pages-#{label}-#{date}.txt", "w:utf-8")
    pages_file.sync = true

    vol = 1
    eof = false
    while !eof
      begin
        website_file = "Website-#{label}-#{date}-#{vol}.txt"
        information("Loading website file : #{website_file}")
        IO.foreach(INPUT + website_file, EOFLINE, encoding: "BOM|UTF-8:-") { |p|
          p p if $b
          page = Page.new(p)
          matrix_file.write(page.to_matrix)
          pages_file.write(page.to_page)
        }
        vol += 1
      rescue Errno::ENOENT => e
        Logging.send(LOG_FILE, Logger::DEBUG, "file <#{website_file}> no exist")
        eof = true
      rescue Exception => e
        eof = true
        Logging.send(LOG_FILE, Logger::ERROR, "#{e.message}")
      end
    end
    matrix_file.close
    pages_file.close
    information("Building matrix and page for #{label} is over")
  end

  def Building_landing_pages(label, date)
    #TODO selectionner le fichier <Traffic_source_landing_page> le plus récent
    #TODO creer une alerte si le fichier attendu est absent
    information("Building landing pages for #{label} is starting")

    landing_pages_direct_file = File.open(TMP + "landing-pages-direct-#{label}-#{date}.txt", "w:utf-8")
    landing_pages_direct_file.sync = true
    landing_pages_referral_file = File.open(TMP + "landing-pages-referral-#{label}-#{date}.txt", "w:utf-8")
    landing_pages_referral_file.sync = true
    landing_pages_organic_file = File.open(TMP + "landing-pages-organic-#{label}-#{date}.txt", "w:utf-8")
    landing_pages_organic_file.sync = true
    vol = 1
    eof = false
    while !eof
      begin
        traffic_source_file = "Traffic-source-landing-page-#{label}-#{date}-#{vol}.txt"
        information("Loading traffic source landing file : #{traffic_source_file}")
        IO.foreach(INPUT + traffic_source_file, EOFLINE2, encoding: "BOM|UTF-8:-") { |p|
          page = Traffic_source.new(p)
          page.set_id_uri(TMP + "pages-#{label}-#{date}.txt")
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
        }
        vol += 1
      rescue Errno::ENOENT => e
        Logging.send(LOG_FILE, Logger::DEBUG, "file <#{traffic_source_file}> no exist")
        eof = true
      rescue Exception => e
        eof = true
        Logging.send(LOG_FILE, Logger::ERROR, "#{e.message}")
      end
    end

    landing_pages_direct_file.close
    landing_pages_referral_file.close
    landing_pages_organic_file.close
    information("Building landing pages for #{label} is over")
  end

  def Building_device_platform(label, date)
    #TODO selectionner le fichier <Device_platform_resolution, Device_platform_plugin> le plus récent
    #TODO creer une alerte si le fichier attendu est absent
    #TODO developper   Building_device_platform
    information("Building device platform for #{label} is starting")
    information("Building device platform for #{label} is over")
  end

  def Choosing_landing_pages(label, date, direct_medium_percent, organic_medium_percent, referral_medium_percent, count_visit)
    #TODO selectionner le fichier <landing_pages_direct, landing_pages_referral, landing_pages_organic> le plus récent
    #TODO creer une alerte si le fichier attendu est absent
    information("Choosing landing pages for #{label} is starting")
    landing_pages_direct_file = File.open(TMP + "landing-pages-direct-#{label}-#{date}.txt", "r:utf-8")
    landing_pages_referral_file = File.open(TMP + "landing-pages-referral-#{label}-#{date}.txt", "r:utf-8")
    landing_pages_organic_file = File.open(TMP + "landing-pages-organic-#{label}-#{date}.txt", "r:utf-8")
    chosen_landing_pages_file = File.open(TMP + "chosen_landing_pages-#{label}-#{date}.txt", "w:utf-8")
    chosen_landing_pages_file.sync =true

    direct_medium_count = (direct_medium_percent * count_visit / 100).to_i
    organic_medium_count = (organic_medium_percent * count_visit/100).to_i
    referral_medium_count = (referral_medium_percent * count_visit /100).to_i

    # choisi les traffic source en fonction de la répartition de l'objectif
    landing_pages_direct_file_lines = File.foreach(TMP + "landing-pages-direct-#{label}-#{date}.txt").inject(0) { |c, line| c+1 }
    p = ProgressBar.create(:title => "Direct landing pages", :starting_at => 0, :total => direct_medium_count, :format => '%t, %c/%C, %a|%w|')
    while direct_medium_count > 0 and landing_pages_direct_file_lines > 0
      chose = rand(landing_pages_direct_file_lines - 1) + 1
      landing_pages_direct_file.rewind
      (chose - 1).times { landing_pages_direct_file.readline(EOFLINE2) }
      page = landing_pages_direct_file.readline(EOFLINE2)
      chosen_landing_pages_file.write(page)
      direct_medium_count -= 1
      p.increment
    end


    landing_pages_organic_file_lines = File.foreach(TMP + "landing-pages-organic-#{label}-#{date}.txt").inject(0) { |c, line| c+1 }
    p = ProgressBar.create(:title => "Organic landing pages", :starting_at => 0, :total => organic_medium_count, :format => '%t, %c/%C, %a|%w|')
    while organic_medium_count > 0 and landing_pages_organic_file_lines > 0
      chose = rand(landing_pages_organic_file_lines - 1) + 1
      landing_pages_organic_file.rewind
      (chose - 1).times { landing_pages_organic_file.readline(EOFLINE2) }
      page = landing_pages_organic_file.readline(EOFLINE2)
      chosen_landing_pages_file.write(page)
      organic_medium_count -= 1
      p.increment
    end

    landing_pages_referral_file_lines = File.foreach(TMP + "landing-pages-referral-#{label}-#{date}.txt").inject(0) { |c, line| c+1 }
    p = ProgressBar.create(:title => "Referral landing pages", :starting_at => 0, :total => referral_medium_count, :format => '%t, %c/%C, %a|%w|')
    while referral_medium_count > 0 and landing_pages_referral_file_lines > 0
      chose = rand(landing_pages_referral_file_lines - 1) + 1
      landing_pages_referral_file.rewind
      (chose - 1).times { landing_pages_referral_file.readline(EOFLINE2) }
      page = landing_pages_referral_file.readline(EOFLINE2)
      chosen_landing_pages_file.write(page)
      referral_medium_count -= 1
      p.increment
    end

    chosen_landing_pages_file.close
    landing_pages_direct_file.close
    landing_pages_referral_file.close
    landing_pages_organic_file.close
    information("Choosing landing pages for #{label} is over")
    execute_next_step("Building_visits", label, date)
  end




  def Choosing_device_platform(label, date, count_visit)
    #TODO selectionner le fichier <Device_platform> le plus récent
    #TODO creer une alerte si le fichier attendu est absent
    #TODO developper  Choosing_device_platform
    information("Choosing device platform for #{label} is starting")
    information("Choosing device platform for #{label} is over")
    execute_next_step("Building_visits", label, date)
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

  def select_file(dir, type_file, label, date)
    if File.exist?("#{dir}#{type_file}-#{label}-#{date}.txt")
      "#{dir}#{type_file}-#{label}-#{date}.txt"
    else
    alert("File <#{dir}#{type_file}-#{label}-#{date}.txt> is not found")
    Dir.glob("#{dir}#{type_file}-#{label}-*.txt").sort{|a, b| b<=>a}[0]
    end
  end

  def alert(msg)
    Logging.send(LOG_FILE, Logger::WARN, msg)
    p "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} => #{msg}"
  end
  module_function :Building_matrix_and_pages
  module_function :Building_landing_pages
  module_function :Building_device_platform
  module_function :Choosing_device_platform
  module_function :Choosing_landing_pages

  module_function :information
  module_function :execute_next_step
  module_function :select_file
  module_function :alert
end