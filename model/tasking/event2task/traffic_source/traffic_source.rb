#encoding:UTF-8
require 'rubygems'
require 'pathname'
require 'ruby-progressbar'
require_relative '../../../../lib/logging'
require_relative '../../../communication'
require_relative 'traffic_source_flow'


#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------

module Tasking
  module TrafficSource
    class TrafficSource

#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------

      OUTPUT = File.expand_path(File.join("..", "..","..", "..","..", "output"), __FILE__)
      TMP = File.expand_path(File.join("..", "..","..", "..", "..","tmp"), __FILE__)
      EOFLINE ="\n"
      SEPARATOR1="%SEP%"
      PROGRESS_BAR_SIZE = 180
      SEC = 1
      MIN = 60 * SEC
      HOUR = 60 * MIN
      DAY = 24 * HOUR

      # Input
      attr :website_label, # le nom  logique du site
           :policy_type,
           :start_time, # heure de dÃ©part de evaluate
           :date_building, #date des fichiers
           :scraped_f, # flow contenant les mots clÃ© scrappÃ©s de semrush
           :repository_f, # flow contenant les mots clÃ©s de issue de semrush complÃ©tÃ©s de ceux de google suggest
           :traffic_source_f #flow contenant les mots clÃ©s de semrush, googleSuggest, evaluÃ©s dans les moteur de
           # recherche google, bing, yahoo Ã  destination de enginebot



      #--------------------------------------------------------------------------------------------------------------
      # initialize
      #--------------------------------------------------------------------------------------------------------------
      # --------------------------------------------------------------------------------------------------------------
      def initialize(website_label, date_building, policy_type)
        @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
        @website_label = website_label
        @policy_type = policy_type
        @date_building = date_building
      end

      def Building_landing_pages(medium)
        @logger.an_event.debug "Building landing pages #{medium} for <#{@policy_type}> <#{@website_label}> <#{@date_building}> is starting"
        begin

          case medium
            when :direct
              convert_to_landing_page("scraping-website", medium) { |p| Traffic_source_direct.new(p) }

            when :referral
              convert_to_landing_page("scraping-traffic-source-referral", medium) { |p| Traffic_source_referral.new(p) }

            when :organic
              convert_to_landing_page("scraping-traffic-source-organic", medium) { |p| Traffic_source_organic.new(p) }

          end


        rescue Exception => e
          @logger.an_event.error ("Building landing pages #{medium} for <#{@policy_type}> <#{@website_label}> is over #{e.message}")
            raise e
        else
          @logger.an_event.debug("Building landing pages #{medium} for <#{@policy_type}> <#{@website_label}> is over")
        end

      end


      private


      def convert_to_landing_page(traffic_source_type_flow, medium, &bloc)

        landing_page_type_flow = "landing-pages-#{medium.to_s}"
        traffic_source_file = Flow.last(TMP, {:type_flow => traffic_source_type_flow,
                                                :label => @website_label,
                                                :policy => @policy_type,
                                           :ext => ".txt"}).last #input
        @logger.an_event.debug "traffic source type flow : #{traffic_source_file.basename}"
        raise IOError, "input flow <#{traffic_source_file.basename}> is missing" unless traffic_source_file.exist? #input

        landing_pages_file = Flow.new(TMP, landing_page_type_flow, @policy_type, @website_label, @date_building) #output
        # on creer le fichier vide.
        # cela permet d'avoir un landing initialisé même si le traffic_source est vide.
        landing_pages_file.empty

        total = 0
        traffic_source_file.volumes.each { |volume| total += volume.count_lines(EOFLINE) }

        pob = ProgressBar.create(:title => title("Building landing #{medium.to_s}"), :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => total, :format => '%t, %c/%C, %a|%w|')
        traffic_source_file.volumes.each { |volume|
          # @logger.an_event.info "Loading vol <#{volume.vol}> of #{traffic_source_file.basename} input file"
          #        pob = ProgressBar.create(:title => "Loading vol <#{volume.vol}> of #{traffic_source_file.basename} input file", :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => volume.count_lines(EOFLINE), :format => '%t, %c/%C, %a|%w|')
          volume.foreach(EOFLINE) { |p|
            source_page = yield(p)
            landing_pages_file.write(source_page.to_s)
            pob.increment
          }
        }
        traffic_source_file.archive_previous
        landing_pages_file.close
        landing_pages_file.archive_previous
      end


      def title(action, policy = @policy_type, website_label = @website_label, date = @date_building)
        [action, policy, website_label, date].join(" | ")
      end



      #--------------------------------------------------------------------------------------------------------------
      # push_flow_to_engine_bot
      #--------------------------------------------------------------------------------------------------------------
      #
      #--------------------------------------------------------------------------------------------------------------
      # input :
      # RAS
      # output :
      #
      #--------------------------------------------------------------------------------------------------------------
      #centre.epilation-laser-definitive.info;/6036.htm;/recherche/;sfr.fr;referral;(not set);1;
      #--------------------------------------------------------------------------------------------------------------
      def push_flow_to_engine_bot(id_file, last_volume = false)
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


    end


  end

end