#!/usr/bin/env ruby -w
# encoding: UTF-8
require 'rubygems'
require "em-http-request"

require_relative '../../../../lib/logging'
require_relative '../../../communication'

require_relative 'traffic_source'


#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------

module Tasking
  module TrafficSource
    SEC = 1
    MIN = 60 * SEC
    HOUR = 60 * MIN
    DAY = 24 * HOUR

    class Page


      include Addressable

      SEPARATOR = "%SEP%"
      NO_LIMIT = 0
      # attribut en input
      attr :url, # url de la page
           :title, # titre recuperï¿½ de la page html
           :id # id logique d'une page
      attr_accessor :links # liens conservï¿½s de la page


      def initialize(id, url, title, links)
        @id = id
        @url = url
        @title = title
        @links = links
      end


      def to_s(*a)
        uri = URI.parse(@url)
        url = "/"
        url = uri.path unless uri.path.nil?
        url += "?#{uri.query}" unless uri.query.nil?
        url += "##{uri.fragment}" unless uri.fragment.nil?

        "#{@id}#{SEPARATOR}#{uri.scheme}#{SEPARATOR}#{uri.host}#{SEPARATOR}#{url}#{SEPARATOR}#{@title}#{SEPARATOR}#{@links}"

      end


# End Class Page ------------------------------------------------------------------------------------------------
    end
    class Direct < TrafficSource


#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------

      EOFLINE ="\n"
      SEPARATOR="%SEP%"
      SEPARATOR1 = '|'
      SCRAPING_WEBSITE = "scraping-website"
# Input
      attr :host # le hostname du site
# Output
      attr :f, #fichier contenant les links
           :ferror, # fichier contenant les links en erreur
           :fleaves #fichier contenant les id des links ne contenant pas de lien
# Private
      attr :start_time, # heure de dÃ©part
           :nbpage, # nbr de page du site
           :idpage, # clÃ© d'identification d'une page
           :known_url, # contient les liens identifiÃ©s
           # 2 moyens pour stopper la recherche  : nombre de page et la duree de recherche, le premier atteint on stoppe
           :count_page, # nombre de page que lon veut recuperer   0 <=> toutes les pages
           :max_duration, # durÃ©e d'exÃ©cution max de la recuperation des lien : en seconde.
           :schemes, #les schemes que l'on veut
           :types, # types de destination du lien : local au site, ou les sous-domaine, ou internet
           :host,
           :run_spawn,
           :start_spawn,
           :stop_spawn,
           :push_file_spawn,
           :saas_host,
           :saas_port, #host et port du serveur de scraping en mode saas
           :time_out #time out de la requet de scraping
#--------------------------------------------------------------------------------------------------------------
# scraping_device_platform_plugin
#--------------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------------------
      def initialize(website_label, date_building, policy_type)
        super(website_label, date_building, policy_type)

        @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
      end

# max_duration (en jours)
      def scraping_pages(url_root, count_page, max_duration, schemes, types)


        @logger.an_event.info("Scraping pages for #{@website_label} for #{@date} is starting")
        parameters = Parameter.new(__FILE__)
        @saas_host = parameters.saas_host.to_s
        @saas_port = parameters.saas_port.to_s
        @time_out = parameters.time_out_saas_scrape.to_i

        @host = url_root
        @count_page = count_page
        @max_duration = max_duration * DAY
        @schemes = schemes
        @types = types
        $sem = Mutex.new
        w = self
        @start_spawn = EM.spawn {
          w.start()
        }
        @stop_spawn = EM.spawn {
          w.stop()
        }
        @run_spawn = EM.spawn { |urls|
          w.run(urls)
        }


        @known_url = Hash.new(0)
        # delete les fichiers existants : on ne conserve qu'un resultat de scrapping par website
        delete_all_output_files
        @start_spawn.notify
      end

      def delete_all_output_files

        @logger.an_event.info("deleting all files #{SCRAPING_WEBSITE}-#{@website_label}* ")
        Dir.entries(TMP).each { |file|
          File.delete(TMP + file) if File.fnmatch("#{SCRAPING_WEBSITE}-#{@website_label}*", file)
        }
      end

      def start

        @nbpage = 0
        @idpage = 1
        urls = Array.new
        urls << [@host, 1] # [url , le nombre d'essai de recuperation de la page associe a l'url]
        @known_url[@host] = @idpage
        @start_time = Time.now

        #creation du fichier de reporting des erreurs d'acces au lien contenus par les pages
        @ferror = Flow.new(TMP, SCRAPING_WEBSITE, @policy_type, @website_label, @date_building, 1, ".error")

        # creation du premier volume de donnÃ©es
        @f = Flow.new(TMP, SCRAPING_WEBSITE, @policy_type, @website_label, @date_building, 1, ".txt")

        #scraping website
        @logger.an_event.debug("scrapping website options : ")
        @logger.an_event.debug("count_page : #{@count_page}")
        @logger.an_event.debug("max duration : #{@max_duration}")
        @logger.an_event.debug("schemes : #{@schemes}")
        @logger.an_event.debug("types : #{@types}")
        @run_spawn.notify urls
        @logger.an_event.info("scrapping of #{@website_label} is running ")
      end


      def run(urls)
        url = urls.shift
        count_try = url[1]
        url = url[0]
        options = {}
        options = proxy(@geolocation.to_json) unless @geolocation.nil?

        url_saas = "http://#{@saas_host}:#{@saas_port}/?action=scrape&"
        url_saas += "&url=#{url}"
        url_saas += "&host=#{@host}"
        url_saas += "&schemes=#{@schemes.join(SEPARATOR1)}"
        url_saas += "&types=#{@types.join(SEPARATOR1)}"
        url_saas += "&count=#{(@count_page > 0) ? @count_page - @idpage : @count_page}"    #limite le nombre de lien dès le saas

        @logger.an_event.debug "url link scraping saas #{url_saas}"

        http = EM::HttpRequest.new(URI.encode(url_saas), options).get
        http.callback {
          # http.reponse = {'url' => @url,
          #                 'title' => @title,
          #                 'links' => @links}
          id = @known_url[url]
          result = JSON.parse(http.response)
          scraped_page = Page.new(id, url, result['title'], result['links'])

          if @count_page > @idpage or @count_page == 0
            $sem.synchronize {
              scraped_page.links.each { |link|
                if @known_url[link] == 0
                  urls << [link, 1]
                  @idpage += 1
                  @known_url[link] = @idpage
                end
              } }
          end
          scraped_page.links.map! { |link| @known_url[link] } unless scraped_page.links.nil?

          output(scraped_page)

          @nbpage += 1
          display(urls)
          if urls.size > 0 and
              (@count_page > @nbpage or @count_page == 0) and
              Time.now - @start_time < @max_duration

            @run_spawn.notify urls
          else
            @stop_spawn.notify
          end

        }

        http.errback {
          @ferror.write("url = #{url} try = #{count_try} Error = #{http.state}\n")
          @logger.an_event.warn("url = #{url} try = #{count_try} Error = #{http.state}")
        }
      end


      def stop

        @f.close
        @ferror.close

      end


      def push_file(id_file, last_volume = false)
        begin
          id_file.push($authentification_server_port,
                       $input_flows_server_ip,
                       $input_flows_server_port,
                       $ftp_server_port,
                       id_file.vol, # on pousse que ce volume
                       last_volume)
          @logger.an_event.info("push flow <#{id_file.basename}> to input flows server (#{$input_flows_server_ip}:#{$input_flows_server_port})")
        rescue Exception => e
          @logger.an_event.debug e
          @logger.an_event.error("cannot push flow <#{id_file.basename}> to input flows server (#{$input_flows_server_ip}:#{$input_flows_server_port})")
        end
      end

      private

      def display(urls)
        delay_from_start = Time.now - @start_time
        mm, ss = delay_from_start.divmod(60) #=> [4515, 21]
        hh, mm = mm.divmod(60) #=> [75, 15]
        dd, hh = hh.divmod(24) #=> [3, 3]
        @logger.an_event.info("#{@website_label} nb page = #{@nbpage}  from start = #{dd} days, #{hh} hours, #{mm} minutes and #{ss.round(0)} seconds  avancement = #{((@nbpage * 100)/(@nbpage + urls.size)).to_i}%  nb/s = #{(@nbpage/delay_from_start).round(2)}  raf #{urls.size} links")
      end

      def output(page)
        @f.write(page.to_s + "#{EOFLINE}")
        if @f.size > Flow::MAX_SIZE
          # informer input flow server qu'il peut telecharger le fichier
          output_file = @f
          @f = output_file.new_volume()
          output_file.close
        end
      end

      def proxy(geolocation)
        if !geolocation[:ip].nil? and !geolocation[:port].nil? and
            !geolocation[:user].nil? and !geolocation[:pwd].nil?

          proxy = {:proxy => {:host => geolocation[:ip], :port => geolocation[:port]}}
        elsif !geolocation[:ip].nil? and !geolocation[:port].nil? and
            geolocation[:user].nil? and geolocation[:pwd].nil?
          proxy = {:proxy => {:host => geolocation[:ip], :port => geolocation[:port]}}
        else
          raise "direct not set geolocation : #{geolocation.to_s}"
        end
        proxy
      end
    end
  end
end

