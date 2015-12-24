#encoding:UTF-8
require 'rubygems'
require 'ruby-progressbar'
require 'addressable/uri'
require_relative '../../../../lib/logging'
require_relative '../../../communication'
require_relative 'backlink'
require_relative 'keyword'
require_relative 'traffic_source'

#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------

module Tasking
  module TrafficSource

    class Referral < TrafficSource

      include Addressable
#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------

      REPOSITORY = "repository-referral"
      SCRAPED = "scraped-referral"
      TRAFFIC_SOURCE = "scraping-traffic-source-referral"
      SEPARATOR1 = "%SEP%"
      attr :hostname, # le hostname du site : sans https:// et /
           :url_root, # http://..../  est utilisÃ© exclusivement par evaluate
           :domain # hostname sans www
# Input

#--------------------------------------------------------------------------------------------------------------
# evaluate
#--------------------------------------------------------------------------------------------------------------
# evalue si la page referencÃ© par le backlink contient bien le landing link.
#--------------------------------------------------------------------------------------------------------------
# input : RAS
#
# output :
# le flow traffic_source contenant lezs referral  Ã  destination de engine bot.
# chaque ligne du fichier contient :
# hostname(landing),
# path(landing),
# path(backlink),
# hostname(backlink),
# title(backlink),
# keyword (referral website),
# uri(referral in results search engine) : soit celui qui pointe sur le landing link, soit une uri du site du referral
# search engine : moteur de recherche utilisÃ© pour trouver l'index
# index : indice de page de results suite Ã  recherche de keyword.
#--------------------------------------------------------------------------------------------------------------
      def evaluate(count_max)

        begin
          # on specifie l'extension car il peut exister un flow ayant le meme type_flow et label quand l'etap de suggestion
          # est en cours d'execution dont le resultat est stockÃ© dans un flow d'extension tmp
          @repository_f = Flow.last(TMP, {:type_flow => REPOSITORY, :policy => @policy_type, :label => @website_label, :ext => ".txt"})

          @traffic_source_f = Flow.new(TMP, TRAFFIC_SOURCE, @policy_type, @website_label, @date_building, 1)
          # c'est pour s'assurer que traffic source ne contiendra que les donnÃ©es que on a scrapÃ© dans cette session car
          # on ne fait que des append
          # c'est pour s'assurer de creer le fichier traffic source pour le pousser vers enginebot, mÃªme vide
          @traffic_source_f.empty

          bl_arr = @repository_f.load_to_array(EOFLINE).shuffle

          @logger.an_event.debug "referral count max : #{count_max}"

          p = ProgressBar.create(:title => "Evaluating backlinks", :length => 100, :starting_at => 0, :total => count_max, :format => '%t, %c/%C, %a|%w|')

          count = 0
          bl_arr.each { |line|
            ll, rl, kw, bl = line.split(SEPARATOR1) #landing link, back link, keyword, result link
            bl = bl.strip
            begin
              bl = Backlink.new(bl)
              bl.evaluate_as_saas(ll)
              @logger.an_event.debug bl
              if bl.is_a_backlink
                kw = Keyword.new(kw)
                uri_rl = URI.parse(rl)
                kw.evaluate_as_saas(uri_rl.hostname)
                @logger.an_event.debug kw
              end

            rescue Exception => e
              @logger.an_event.warn "evaluate backlinks for #{@website_label} and #{@date_building} : #{e.message}"

            else
              @logger.an_event.debug "result of evaluation of backlink #{bl.to_s}"

              if bl.is_a_backlink and kw.engines.size > 0
                kw.engines.each { |engine, data|
                  uri = URI.parse(ll)
                  line = [uri.scheme, uri.hostname, uri.path, bl.path, bl.hostname, "referral", "(not set)", bl.title, kw.words, rl, engine, data[:index]].join(SEPARATOR1)

                  @traffic_source_f.append("#{line}#{EOFLINE}")

                }
                count += 1
                p.increment
                @logger.an_event.debug "backlink #{bl.to_s} evaluated successful for #{@website_label} at #{@date_building}"

              else
                @logger.an_event.debug "backlink #{bl.to_s} evaluated not successful for #{@website_label} at #{@date_building}"

              end
              break if count >= count_max

            end
          }

        rescue Exception => e
          @logger.an_event.error "backlinks evaluated for #{@website_label} and #{@date_building} : #{e.message}"
          raise
        else
          @logger.an_event.info "backlinks evaluated for #{@website_label} and #{@date_building} save to #{@traffic_source_f.basename}"
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
# cree le ereferentiel de referral
#--------------------------------------------------------------------------------------------------------------
# input :
# RAS
# output :
# flow (repository-referral) contenant les backlinks
#--------------------------------------------------------------------------------------------------------------
# si staging <> developmnet alors recherche des Backlink en mode saas avec le serveur Saas
# si staging = development alors recherche des backlink en local
# si majestic retoune une liste de baclink alors recherche des keyword pour chaque backlinks
# si erreur lors de interrogation majestic ou si aucun backlink retournÃ©er par majestic alors :
# - soit reutilisation d'un referentiel prÃ©cÃ©dent si il existe
# - soit creation d'un referentiel vide pour permettre l'execution de Evaluation_backlinks sans erreur
#--------------------------------------------------------------------------------------------------------------
      def make_repository(url_root)
        begin
          @url_root = url_root
          @hostname = URI.parse(@url_root).hostname
          @domain = "#{@hostname.split(".")[1]}.#{@hostname.split(".")[2]}"

          new_repository = scrape
          add_keyword_to_repository if new_repository

        rescue Exception => e
          @logger.an_event.fatal "repository referral for #{@website_label} and #{@date_building} : #{e.message}"

        else
          @logger.an_event.info "repository referral for #{@website_label} and #{@date_building}"

        ensure


        end
      end


#--------------------------------------------------------------------------------------------------------------
# scrape
#--------------------------------------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------------------------------------
# input :
# RAS
# output :
# flow (repository-referral) contenant les backlik de chaque landing link
#--------------------------------------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------------------------------------


      private

      def scrape
        #permet de savoir si un nouveau repository a Ã©tÃ© crÃ©Ã© ou si on reutiliser un ancien
        new_repository = false

        begin

          backlinks = Backlink.scrape_as_saas(@hostname)

          @logger.an_event.info "backlinks scraped for #{@website_label} and #{@date_building}"

        rescue Exception => e
          @logger.an_event.error "backlinks scraped for #{@website_label} and #{@date_building} : #{e.message}"

          reuse_old_repository

        else
          if backlinks.size > 0
            # tant que l'etap de recuperation des keyword n'est pas terminÃ© alors le repository est  stockÃ© dans un flow temporaire :
            # extension = tmp
            @repository_f = Flow.new(TMP, REPOSITORY, @policy_type, @website_label, @date_building, 1, ".tmp")
            backlinks.each { |row| @repository_f.write("#{row.join(SEPARATOR1)}#{EOFLINE}") }
            @repository_f.close unless @repository_f.nil?
            new_repository = true

          else
            # aucun backlink recuperer de majestic : (quota majestic atteint, aucun backlink pour ce website)
            # => reutilisation d'un ancien repository ou creation d'un noveau repository vide
            reuse_old_repository

          end

        ensure
          return new_repository #conserver le return sinon la valeur n'est jamais retournÃ©

        end
      end


      def reuse_old_repository
        @logger.an_event.info "try to use old repository referral for #{@website_label} and #{@date_building}"

        begin
          @repository_f = Flow.last(TMP, {:type_flow => REPOSITORY, :policy => @policy_type, :label => @website_label})

        rescue Exception => e
          #old repository not found => create an empty one
          @repository_f = Flow.new(TMP, REPOSITORY, @policy_type, @website_label, @date_building, 1)
          @repository_f.empty

          @logger.an_event.warn "use empty repository referral #{@repository_f.basename} for #{@website_label} and #{@date_building}"

        else
          @logger.an_event.warn "use old repository referral #{@repository_f.basename} for #{@website_label} and #{@date_building}"

        end

      end


      def add_keyword_to_repository
        begin
          bl_arr = @repository_f.load_to_array(EOFLINE)
          keywords_arr = []
          known_bl = [] # ensemble de mot clÃ© dÃ©jÃ  enregistrÃ©

          opts = {:range => :selection}

          p = ProgressBar.create(:title => "Add keywords to backlinks", :length => 100, :starting_at => 0, :total => bl_arr.size, :format => '%t, %c/%C, %a|%w|')

          @repository_f.empty

          bl_arr.each { |line|
            ll, bl = line.split(SEPARATOR1)

            begin
              uri_bl = URI.parse(bl)
            rescue Exception => e
              @logger.an_event.debug "parse referral #{bl} : #{e.message}"

            else
              begin
                # si le path ='/' alors semrush le supprime et ne considÃ¨re que le hostname
                if uri_bl.path != "/" and !known_bl.include?("#{uri_bl.hostname}#{uri_bl.path}")

                  keywords_arr = Keyword.scrape_as_saas("#{uri_bl.hostname}#{uri_bl.path}", opts)

                  keywords_arr.each { |referral_uri_search, keywords|
                    @repository_f.write("#{[ll, referral_uri_search, keywords, bl].join(SEPARATOR1)}#{EOFLINE}")
                  }
                  known_bl << "#{uri_bl.hostname}#{uri_bl.path}"
                end

              rescue Exception => e
                @logger.an_event.debug "scraped keywords for referral #{uri_bl.hostname}/#{uri_bl.path} : #{e.message}"

              end

              begin
                unless known_bl.include?(uri_bl.hostname)

                  keywords_arr = Keyword.scrape_as_saas(uri_bl.hostname, opts)

                  keywords_arr.each { |referral_uri_search, keywords|
                    @repository_f.write("#{[ll, referral_uri_search, keywords, bl].join(SEPARATOR1)}#{EOFLINE}")
                  }
                  known_bl << uri_bl.hostname
                end
              rescue Exception => e
                @logger.an_event.debug "scraped keywords for referral #{uri_bl.hostname}: #{e.message}"

              end

            ensure
              p.increment

            end
          }

        rescue Exception => e
          @logger.an_event.error "keywords scraped for referral #{@website_label} and #{@date_building}: #{e.message}"

        else
          @logger.an_event.info "keywords scraped for referral #{@website_label} and #{@date_building}"

        ensure
          @repository_f.rename_ext(".txt")

        end
      end


    end

  end


end