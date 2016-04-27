#encoding:UTF-8
require 'rubygems'
require 'pathname'
require 'ruby-progressbar'
require_relative 'traffic_source'
require_relative '../../../../lib/logging'

#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------

module Tasking
  module TrafficSource
    class Default < TrafficSource

      #------------------------------------------------------------------------------------------
      # Globals variables
      #------------------------------------------------------------------------------------------
      REPOSITORY = "repository-organic" #dans TMP
      TRAFFIC_SOURCE = "scraping-traffic-source-organic" #dans TMP
      SEPARATOR="%SEP%"
      # Input

      def initialize(website_label, date, policy_type)
        @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
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
      # utiliser par policy rank
      #--------------------------------------------------------------------------------------------------------------

      def make_repository(variables)
        # :keywords => @data[:keywords],
        # :label_advertising => @data[:label_advertising]
        begin
          str = variables.map { |k, v| v }.join(SEPARATOR)

          @repository_f = Flow.new(TMP, REPOSITORY, @policy_type, @website_label, @date_building, 1, ".txt")
          @repository_f.write("#{str}#{EOFLINE}")

        rescue Exception => e
          @logger.an_event.fatal "repository organic for #{@website_label} and #{@date_building} : #{e.message}"
          raise e
        else
          @logger.an_event.info "repository organic for #{@website_label} and #{@date_building}"

        ensure

          @repository_f.close
          @repository_f.archive_previous
        end


      end

      #--------------------------------------------------------------------------------------------------------------
      # evaluate
      #--------------------------------------------------------------------------------------------------------------
      # construit par defaut une evlautation pour seaattack ;
      # la page d'index sera tj 1 ;
      # ajoute en fin de fichier output le libelle de l'adwrod : label_advertising
      #--------------------------------------------------------------------------------------------------------------
      # input :
      # reposotiru des keywords,  repository contient :
      #  un couple keywords%SEP%label_advertising     issue de statupweb pour la policy seaattack
      #
      # output :
      # flow (TRAFFIC_SOURCE)
      #--------------------------------------------------------------------------------------------------------------
      # utiliser par seaattack
      #--------------------------------------------------------------------------------------------------------------
      def evaluate(count_max, url_root)

        begin
          @logger.an_event.debug "organic count max : #{count_max}"
          @logger.an_event.debug "organic url_root : #{url_root}"

          # on specifie l'extension car il peut exister un flow ayant le meme type_flow et label quand l'etap de suggestion
          # est en cours d'execution dont le resultat est stockÃ© dans un flow d'extension tmp
          # repository contient :
          # soit un couple keywords%SEP%label issue de statupweb pour la policy seaattack
          @repository_f = Flow.last(TMP, {:type_flow => REPOSITORY, :policy => @policy_type, :label => @website_label, :ext => ".txt"})

          @traffic_source_f = Flow.new(TMP, TRAFFIC_SOURCE, @policy_type, @website_label, @date_building, 1)
          # c'est pour s'assurer que traffic source ne contiendra que les donnÃ©es que on a scrapÃ© dans cette session car
          # on ne fait que des append dans keyxord
          @traffic_source_f.empty if @traffic_source_f.exist?

          keyword = @repository_f.load_to_array(EOFLINE)[0]
          @logger.an_event.debug "organic keyword : #{keyword}"

          uri = URI.parse(url_root)
          @logger.an_event.debug "organic uri : #{uri}"

          p = ProgressBar.create(:title => "Evaluating keywords", :length => 100, :starting_at => 0, :total => count_max, :format => '%t, %c/%C, %a|%w|')

          count_max.times { | |
            line = [uri.scheme, uri.hostname, uri.path, "(not set)", "google", "organic", keyword, 1].join(SEPARATOR)
            @logger.an_event.debug "organic line : #{line}"

            @traffic_source_f.append("#{line}#{EOFLINE}")

            # new flow
            @traffic_source_f = @traffic_source_f.new_volume() if @traffic_source_f.size > Flow::MAX_SIZE

            p.increment

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

      private


    end


  end

end