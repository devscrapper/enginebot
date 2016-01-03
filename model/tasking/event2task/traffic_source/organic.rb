#encoding:UTF-8
require 'rubygems'
require 'addressable/uri'
require 'ruby-progressbar'
require_relative '../../../../lib/logging'
require_relative '../../../communication'
require_relative 'keyword'
require_relative 'traffic_source'
#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------

module Tasking
  module TrafficSource
    class Organic < TrafficSource
      include Addressable

      #------------------------------------------------------------------------------------------
      # Globals variables
      #------------------------------------------------------------------------------------------
      REPOSITORY = "repository-organic" #dans TMP
      SCRAPED = "scraped-organic" #dans TMP
      TRAFFIC_SOURCE = "scraping-traffic-source-organic" #dans OUTPUT
      WORDS_COUNT_MAX_IN_KEYWORD = 5 # nombre de mot max dans un mot clÃ©
      SEPARATOR1 = "%SEP%"
      attr :max_duration, #durÃ©e d'exÃ©cution max que l'on laisse au scraping
           :hostname, # le hostname du site : sans https:// et /
           :url_root, # http://..../  est utilisÃ© exclusivement par evaluate
           :domain # hostname sans www


      #--------------------------------------------------------------------------------------------------------------
      # evaluate
      #--------------------------------------------------------------------------------------------------------------
      # calcule une liste de mot clÃ© au moyen du service google suggest et d'une stimulation : ajout d'une lettre de
      # l'alphabet pour suggÃ©rer Ã  google des solutions.
      #--------------------------------------------------------------------------------------------------------------
      # input :
      # count_max : nombre max de mot clÃ© attendus pour les visits du jour ; founit par l'objectif du jour calculÃ© hebdomadairement
      # par enginebot ; est utilisÃ© exclusivement par evaluate
      #
      # output :
      # le flow enrichit des suggestions google. Ces mot clÃ© ne seront pas associÃ© Ã  un landing_link. Il sera calculÃ©
      # lors de l'Ã©valuation (il devra contenir le domain du website.)
      #--------------------------------------------------------------------------------------------------------------

      def evaluate(count_max, url_root)

        begin
          @url_root = url_root
          @hostname = URI.parse(@url_root).hostname
          @domain = "#{@hostname.split(".")[1]}.#{@hostname.split(".")[2]}"

          # on specifie l'extension car il peut exister un flow ayant le meme type_flow et label quand l'etap de suggestion
          # est en cours d'execution dont le resultat est stockÃ© dans un flow d'extension tmp
          @repository_f = Flow.last(TMP, {:type_flow => REPOSITORY, :policy => @policy_type, :label => @website_label, :ext => ".txt"})

          @traffic_source_f = Flow.new(TMP, TRAFFIC_SOURCE, @policy_type, @website_label, @date_building, 1)
          # c'est pour s'assurer que traffic source ne contiendra que les donnÃ©es que on a scrapÃ© dans cette session car
          # on ne fait que des append dans keyxord et backlink
          @traffic_source_f.empty if @traffic_source_f.exist?

          kw_arr = @repository_f.load_to_array(EOFLINE).shuffle

          @logger.an_event.debug "organic count max : #{count_max}"

          p = ProgressBar.create(:title => "Evaluating keywords", :length => 100, :starting_at => 0, :total => count_max, :format => '%t, %c/%C, %a|%w|')

          count = 0
          kw_arr.each { |keyword|

            begin
              kw = Keyword.new(keyword)

              kw.evaluate_as_saas(@domain)

            rescue Exception => e
              @logger.an_event.warn "evaluate keywords for #{@website_label} and #{@date_building} : #{e.message}"

            else
              @logger.an_event.debug "result of evaluation of keyword #{kw.to_s}"

              if kw.engines.size > 0
                kw.engines.each { |engine, data|
                  uri = URI.parse(data[:url.to_s])
                  line = [uri.scheme, uri.hostname, uri.path, "(not set)", engine, "organic", kw.words, data[:index.to_s]].join(SEPARATOR1)

                  @traffic_source_f.append("#{line}#{EOFLINE}")

                  # new flow
                  @traffic_source_f = @traffic_source_f.new_volume() if @traffic_source_f.size > Flow::MAX_SIZE
                }

                count += 1
                p.increment
                @logger.an_event.debug "keyword #{keyword} evaluated successful for #{@website_label} at #{@date_building}"

              else
                @logger.an_event.debug "keyword #{keyword} evaluated not successful for #{@website_label} at #{@date_building}"

              end
              break if count >= count_max

            end
          }

        rescue Exception => e
          @logger.an_event.error "evaluate keywords for #{@website_label} and #{@date_building} : #{e.message}"
          raise e
        else
          @logger.an_event.info "keywords evaluated for #{@website_label} and #{@date_building} save to #{@traffic_source_f.basename}"
          @traffic_source_f.close

        ensure
          @repository_f.close unless @repository_f.nil?

        end
      end

      def initialize(website_label, date, policy_type)
        super(website_label, date, policy_type)
      end

      #--------------------------------------------------------------------------------------------------------------
      # make_repository
      #--------------------------------------------------------------------------------------------------------------
      # interroge semrush pour recuperer une liste de mot clÃ© et leur landing link
      #--------------------------------------------------------------------------------------------------------------
      # input :
      # RAS
      # output :
      # flow (repository-organic.txt) contenant les mots clÃ©
      #--------------------------------------------------------------------------------------------------------------
      # pour pallier Ã  des contrats semrush qui arrive a Ã©chÃ©ance et eviter de trop solliciter semrush dans les phase de veloppemet
      # si staging = developmnet alors pas d'interrogation de semrush mais utilisation d'un ancien flow de scraped organic issu de semrush
      # si staging est <> de development alors interrogation de semrush
      # si semrush n'est pas joignable ou ne veut pas repondre alors on utilise un ancien flow de scraped organic comme
      # pour le staging develpoment
      # dans tous les cas si il n'existe aucun flow scraped organic alors pas de creation de repository
      #--------------------------------------------------------------------------------------------------------------
      def make_repository (url_root, max_duration)
        @url_root = url_root
        @hostname = URI.parse(@url_root).hostname
        @domain = "#{@hostname.split(".")[1]}.#{@hostname.split(".")[2]}"
        @max_duration = max_duration * DAY
        begin
          scrape_as_saas
          suggest_as_saas

        rescue Exception => e
          @logger.an_event.fatal "repository organic for #{@website_label} and #{@date_building} : #{e.message}"
          raise e
        else
          @logger.an_event.info "repository organic for #{@website_label} and #{@date_building}"
        end
      end


      #--------------------------------------------------------------------------------------------------------------
      # scrape
      #--------------------------------------------------------------------------------------------------------------
      # interroge semrush pour recuperer une liste de mot clÃ© et leur landing link
      #--------------------------------------------------------------------------------------------------------------
      # input :
      # RAS
      # output :
      # flow (repository-organic.txt) contenant les mots clÃ© et leur landing link : url;keywords
      #--------------------------------------------------------------------------------------------------------------
      # si semrush n'est pas joignable ou ne veut pas repondre alors on utilise un ancien flow de scraped organic comme
      # pour le staging develpoment
      #--------------------------------------------------------------------------------------------------------------


      def scrape_as_saas
        begin
          @scraped_f = Flow.new(TMP, SCRAPED, @policy_type, @website_label, @date_building, 1)

          opts = {:scraped_f => @scraped_f.absolute_path}
          Keyword.scrape_as_saas(@hostname, opts)

          @logger.an_event.info "keywords scraped for #{@website_label} and #{@date_building}"

          scraped_flow_to_repository_flow

        rescue Exception => e
          @logger.an_event.error "scraped keywords for #{@website_label} and #{@date_building}: #{e.message}"

          reuse_old_scraped
        else


        ensure
          @repository_f.close

        end
      end

      private


      #--------------------------------------------------------------------------------------------------------------
      # suggest_keywords
      #--------------------------------------------------------------------------------------------------------------
      #
      #--------------------------------------------------------------------------------------------------------------
      # input :
      # RAS
      # output :
      # flow (keywords_%website%_%date%_%vol%.txt) contenant les mots clÃ© et leur landing link : url;keywords
      #--------------------------------------------------------------------------------------------------------------
      #
      #--------------------------------------------------------------------------------------------------------------

      def suggest_as_saas
        # charge en memoire le ficiher de mot clÃ© scrappÃ© Ã  partir de semrush

        kw_known = @repository_f.load_to_array(EOFLINE)
        kw_count_saved = kw_known.size
        kw_count_history = kw_known.size
        @logger.an_event.debug "known keyword (#{kw_count_saved}) : #{kw_known}"

        # dÃ©termine la liste des mots clÃ© devant faire parti de la liste des mot clÃ© Ã  traiter
        p = ProgressBar.create(:title => "building keywords todo list", :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => kw_known.size, :format => '%t, %c/%C, %a|%w|')
        kw_to_do = Array.new(kw_known).delete_if { |kw|
          kw.strip!
          p.increment
          # elimne les mot clÃ© a traiter qui ont un nombre de mot > WORDS_COUNT_MAX_IN_KEYWORD
          kw if kw.split.count >= WORDS_COUNT_MAX_IN_KEYWORD
        }
        @logger.an_event.debug "first todo list (#{kw_to_do.size}) : #{kw_to_do}"


        start_time = Time.now
        day = start_time.day

        while kw_to_do.size > 0 and Time.now - start_time < @max_duration
          begin
            keyword = kw_to_do.shift
            @logger.an_event.debug "current keyword : #{keyword}"

            # les mots clÃ© en doublon ont dÃ©jÃ  Ã©tÃ© supprimÃ©s par suggest
            suggested_kw = Keyword.suggest_as_saas(keyword)
            @logger.an_event.debug "#{suggested_kw.size} suggested keyword for #{keyword} : "
            @logger.an_event.debug suggested_kw

            suggested_kw.each { |kw|
              # sauvegarde du mot clÃ© dans le fichier ssi :
              # le nombre de mot clÃ© max n'est pas atteint
              # le mot clÃ© n'est pas connu
              # le mot clÃ© contient un nombre de mot <= WORDS_COUNT_MAX_IN_KEYWORD


              if !kw_known.include?(kw) and
                  kw.split.count <= WORDS_COUNT_MAX_IN_KEYWORD

                # sauvegarde du nouveau mot clÃ©
                @repository_f.append("#{kw}#{EOFLINE}")
                kw_count_saved += 1
                kw_known << kw
                @logger.an_event.debug "keyword <#{kw}> save to repository and add to known list"

                #ajout du nouveau Ã  la to_do liste de mot clÃ© a traiter ssi le nombre de mot est < WORDS_COUNT_MAX_IN_KEYWORD
                if kw.split.count < WORDS_COUNT_MAX_IN_KEYWORD
                  kw_to_do << kw
                  @logger.an_event.debug "keyword <#{kw}> add to todo list"

                end
              else


              end
            }

          rescue Exception => e
            @logger.an_event.warn "suggestion for #{@website_label} and #{@date_building} : #{e.message}"

          else
            @logger.an_event.info "#{kw_count_saved} keywords suggested"
            @logger.an_event.info "keywords todo list size to process = #{kw_to_do.size}"

          ensure
          end

        end


        @logger.an_event.info "#{kw_count_saved - kw_count_history} suggested keywords for #{@website_label} and #{@date_building} save to #{@repository_f.basename}"
        @repository_f.rename_ext(".txt")
        @repository_f.archive_previous

      end

      def scraped_flow_to_repository_flow
        # tant que l'etap de suggestion n'est pas terminÃ© alors le repository est  stockÃ© dans un flow temporaire :
        # extension = tmp
        @repository_f = Flow.new(TMP, REPOSITORY, @policy_type, @website_label, @date_building, 1, ".tmp")

        CSV.open(@scraped_f.absolute_path,
                 "r:bom|utf-8",
                 {headers: true,
                  converters: :numeric,
                  header_converters: :symbol}).map.each { |row|
          @repository_f.write("#{row[:keyword]}#{EOFLINE}")
        }

      end

      #--------------------------------------------------------------------------------------------------------------
      # reuse_old_scraped
      #--------------------------------------------------------------------------------------------------------------
      #
      #--------------------------------------------------------------------------------------------------------------
      # input :
      # flow (scraped-organic.txt)
      # output :
      # flow (repository-organic.txt) contenant les mots clÃ© et leur landing link : url;keywords
      #--------------------------------------------------------------------------------------------------------------
      #
      #--------------------------------------------------------------------------------------------------------------
      def reuse_old_scraped
        @logger.an_event.info "try to use old scraped #{SCRAPED} flow for #{@website_label} and #{@date_building}"
        @scraped_f = Flow.last(TMP, {:type_flow => SCRAPED, :policy => @policy_type, :label => @website_label})

        scraped_flow_to_repository_flow

        @logger.an_event.warn "use old scraped #{SCRAPED} flow #{@scraped_f.basename} for #{@website_label} and #{@date_building}"
      end
    end


  end

end