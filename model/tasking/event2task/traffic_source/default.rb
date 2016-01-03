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

      # Input


      def initialize(website_label, date,policy_type)
        @repository_tf = REPOSITORY
        @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
        super(website_label, date,policy_type)
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
      def make_repository(keywords)
        begin
          @repository_f = Flow.new(TMP, @repository_tf,@policy_type, @website_label, @date, 1, ".txt")
          @repository_f.write("#{keywords}#{EOFLINE}")

        rescue Exception => e
          @logger.an_event.fatal "repository organic for #{@website_label} and #{@date} : #{e.message}"
          raise e
        else
          @logger.an_event.info "repository organic for #{@website_label} and #{@date}"

        ensure

          @repository_f.close
          @repository_f.archive_previous
        end


      end


      private


    end


  end

end