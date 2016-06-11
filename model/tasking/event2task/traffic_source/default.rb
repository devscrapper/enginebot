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
      #
      #--------------------------------------------------------------------------------------------------------------
      # input :
      # Array contenant des mot clés
      # output :
      # flow (repository-organic.txt) contenant les mots clÃ©
      #--------------------------------------------------------------------------------------------------------------
      # utiliser par policy rank
      #--------------------------------------------------------------------------------------------------------------

      def make_repository(keywords)
        # :keywords => @data[:keywords],
        # :label_advertisings => @data[:label_advertisings]
        begin

          @repository_f = Flow.new(TMP, REPOSITORY, @policy_type, @website_label, @date_building, 1, ".txt")
          keywords.each{|keyword|
                    @repository_f.write("#{keyword}#{EOFLINE}")
          }


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
      # aucune uri ne sera en output : uri.scheme, uri.hostname, uri.path
      #--------------------------------------------------------------------------------------------------------------
      # input :
      # reposotiru des keywords,  repository contient :
      #  un couple keywords%SEP%label_advertisings     issue de statupweb pour la policy seaattack
      #
      # output :
      # flow (TRAFFIC_SOURCE)
      # not use%SEP%not use%SEP%not use%SEP%(not set)%SEP%google%SEP%organic%SEP%keyword%SEP%1
      #--------------------------------------------------------------------------------------------------------------
      # utiliser par seaattack
      #--------------------------------------------------------------------------------------------------------------
      def evaluate(count_max)

        begin
          @logger.an_event.debug "organic count max : #{count_max}"

          # on specifie l'extension car il peut exister un flow ayant le meme type_flow et label quand l'etap de suggestion
          # est en cours d'execution dont le resultat est stockÃ© dans un flow d'extension tmp
          # repository contient :
          # soit un couple keywords%SEP%label issue de statupweb pour la policy seaattack
          @repository_f = Flow.last(TMP, {:type_flow => REPOSITORY, :policy => @policy_type, :label => @website_label, :ext => ".txt"})

          @traffic_source_f = Flow.new(TMP, TRAFFIC_SOURCE, @policy_type, @website_label, @date_building, 1)
          # c'est pour s'assurer que traffic source ne contiendra que les donnÃ©es que on a scrapÃ© dans cette session car
          # on ne fait que des append dans keyxord
          @traffic_source_f.empty if @traffic_source_f.exist?

          p = ProgressBar.create(:title => "Evaluating keywords", :length => 100, :starting_at => 0, :total => count_max, :format => '%t, %c/%C, %a|%w|')

          count_max.times { | |
          keyword = @repository_f.load_to_array(EOFLINE).shuffle[0]
          @logger.an_event.debug "organic keyword : #{keyword}"
            line = ["not use", "not use", "not use", "(not set)", "google", "organic", keyword, 1].join(SEPARATOR)
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