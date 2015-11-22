require_relative '../../model/flowing/flow2task/inputs'
require_relative '../flow'

module Flowing
  class Flowlist
    class FlowlistException < StandardError;
    end
    INPUT = File.dirname(__FILE__) + "/../../input"

    attr :last_volume,
         :input_flow,
         :logger

    def initialize(data)
      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
      @last_volume = data["last_volume"]
      @input_flow = Flow.from_basename(INPUT, data["basename"])
      @input_flow.get(data["ip_ftp_server"], data["port_ftp_server"], data["user"], data["pwd"])
    end

    def scraping_website
      @logger.an_event.info "input flow #{@input_flow.basename} downloaded" if @last_volume
      #execute { Inputs.new.Building_matrix_and_pages(@input_flow) } if @last_volume
      # n'est plus déclencher par l'arrivé du flow mais par le scheduler quotidiennement voir object2event/policy.rb
      #20150812 : Building_matrix_and_pages n'est plus déclenché. object2event/policy.rb délcenche à la place Building_landing_page
      #20150812 : l'archivage n'est donc plus réalisé, donc le sera réalisé ici à toute nouvelle réception de fichier
      @input_flow.archive_previous if @last_volume
    end

    def scraping_traffic_source_organic
      @logger.an_event.info "flow #{@input_flow.basename} downloaded" if @last_volume
      @input_flow.archive_previous if @last_volume
    end

    def scraping_traffic_source_referral
      @logger.an_event.info "flow #{@input_flow.basename} downloaded" if @last_volume
      if @last_volume
        # on regarde si il existe un input flow
        # si il existe un input_flow et que le nouvel inut_flow a une taille > 0 alors on archive celui déjà présent
        # si il existe u input_flow et que le nouvel inut_flow a une taille = 0 alors on conserve celui déjà présent
        # si il n'existe pas d'input_flow alors on conserve le nouvel input_flow
        # tout ce la pour gérer le scraping des referral aupres de majestic qui peut ne rien retourner.
        # cela pose un pb si il n'ya jamais de scraing reussi et donc pas de traffic_source, ni de landing
        arr = Flow.list(INPUT, {:type_flow => @input_flow.type_flow,
                                :label => @input_flow.label,
                                :policy => @input_flow.policy,
                             :ext => @input_flow.ext})
        @input_flow.archive_previous if arr.size > 0 and @input_flow.size > 0
      end
    end

    def scraping_device_platform_plugin
      execute { Inputs.new(@input_flow.label, @input_flow.date, @input_flow.policy).Building_device_platform } if @last_volume
    end

    def scraping_device_platform_resolution
      execute { Inputs.new(@input_flow.label, @input_flow.date, @input_flow.policy).Building_device_platform } if @last_volume
    end

    def scraping_hourly_daily_distribution
      execute { Inputs.new(@input_flow.label, @input_flow.date, @input_flow.policy).Building_hourly_daily_distribution(@input_flow) } if @last_volume
    end

    def scraping_behaviour
      execute { Inputs.new(@input_flow.label, @input_flow.date, @input_flow.policy).Building_behaviour(@input_flow) } if @last_volume
    end

    private
    def execute (&block)
      begin
        yield
      rescue Exception => e
        @logger.an_event.debug e
        raise FlowlistException, e
      end
    end
  end
end
