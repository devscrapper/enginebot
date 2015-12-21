require_relative '../reporting'
#TODO essayer de fsionner avec traffic_source.rb
module Tasking
  module TrafficSource
    EOFLINE = "\n"


    class Chosens

      attr :label,
           :date_building,
           :policy_type

      def initialize(label, date_building, policy_type)
        @label = label
        @date_building = date_building
        @policy_type = policy_type
        @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
      end

      def Choosing_landing_pages(direct_medium_percent, organic_medium_percent, referral_medium_percent, count_visit)
        # 2014/09/08 : les referral ne sont plus captés à partir de Google Analytics car ils n'ont pas de valeur. Cela sera
        #remplacer à terme par un service de recherche de backlink
        # En attendant, au fichier referral n'est produit par scraperbot => bug remonté par  Choosing_landing_medium_in_mem
        # on commente alors : Choosing_landing_medium_in_mem(label, date, "referral", medium_count, chosen_landing_pages_file)
        # tant que le srrvice de backlink n'a pas produit de fichier pour referral.
        # referral_medium_percent est forcé à zero pour éviter un bug si dans statupweb on saisit un pourcentage pour referral.
        @logger.an_event.debug "Choosing landing pages for #{@policy_type} #{@label} #{@date_building} is starting"

        reporting = Reporting.new(@label, @date_building, @policy_type)
        reporting.landing_pages_obj(direct_medium_percent, organic_medium_percent, referral_medium_percent)
        reporting.to_file("landing objective")

        Flow.new(TMP, "chosen-landing-pages", @policy_type, @label, @date_building).delete
        chosen_landing_pages_file = Flow.new(TMP, "chosen-landing-pages", @policy_type, @label, @date_building) #output

        if organic_medium_percent > 0
          organic_medium_count = (direct_medium_percent * count_visit / 100).to_i

          Choosing_landing_medium_in_mem("organic", organic_medium_count, chosen_landing_pages_file)
        else
          organic_medium_count = 0
        end

        landing_pages_referral_file = Flow.new(TMP, "landing-pages-referral", @policy_type, @label, @date_building).last
        if referral_medium_percent == 0 or landing_pages_referral_file.size == 0
          referral_medium_count = 0

        else

          referral_medium_count = (referral_medium_percent * count_visit / 100).to_i

          Choosing_landing_medium_in_mem("referral", referral_medium_count, chosen_landing_pages_file)


        end

        direct_medium_count = count_visit - (organic_medium_count + referral_medium_count)

        Choosing_landing_medium_in_mem("direct", direct_medium_count, chosen_landing_pages_file) if direct_medium_percent > 0

        chosen_landing_pages_file.close
        chosen_landing_pages_file.archive_previous
        @logger.an_event.debug "Choosing landing pages for <#{@policy_type}> <#{@label}> <#{@date_building}> is over"
      end

      private
      def Choosing_landing_medium_in_mem(medium_type, medium_count, chosen_landing_pages_file)
        @logger.an_event.debug "count #{medium_type} medium #{medium_count}"
        # ouverture du dernier fichier créé
        landing_pages_file = Flow.new(TMP, "landing-pages-#{medium_type}", @policy_type, @label, @date_building).last
        raise IOError, "tmp flow landing-pages-#{medium_type} for <#{@policy_type}> <#{@label}> for <#{@date_building}> is missing" if landing_pages_file.nil?
        begin
          landing_pages_array = landing_pages_file.load_to_array(EOFLINE)
          landing_pages_file_lines = landing_pages_array.size
          p = ProgressBar.create(:title => title("Choosing landing #{medium_type}"), :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => medium_count, :format => '%t, %c/%C, %a|%w|')
          while medium_count > 0 and landing_pages_file_lines > 0
            chose = rand(landing_pages_file_lines)
            page = landing_pages_array[chose]
            chosen_landing_pages_file.append(page + EOFLINE)
            medium_count -= 1
            p.increment
          end

        rescue Exception => e
          @logger.an_event.error "cannot chose landing page of medium <#{medium_type}> for #{@policy_type} #{@label} : #{e.message}"
        ensure
          landing_pages_file.close
        end

      end

      def Choosing_landing_medium_with_file(medium_type, medium_count, chosen_landing_pages_file)
        # ouverture du dernier fichier créé
        begin
          landing_pages_file = Flow.new(TMP, "landing-pages-#{medium_type}", @policy_type, @label, @date_building).last
          raise IOError, "tmp flow landing-pages-#{medium_type} for <#{@label}> for <#{@date_building}> is missing" if landing_pages_file.nil?

          landing_pages_file_lines = landing_pages_file.count_lines(EOFLINE)
          p = ProgressBar.create(:title => title("Choosing landing #{medium_type}"), :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => medium_count, :format => '%t, %c/%C, %a|%w|')
          while medium_count > 0 and landing_pages_file_lines > 0
            chose = rand(landing_pages_file_lines - 1) + 1
            landing_pages_file.rewind
            (chose - 1).times { landing_pages_file.readline(EOFLINE) }
            page = landing_pages_file.readline(EOFLINE)
            chosen_landing_pages_file.append(page)
            medium_count -= 1
            p.increment
          end

        rescue Exception => e
          @logger.an_event.error "cannot chose landing page of medium <#{medium_type}> for #{@policy_type} #{@label}"
        end
        landing_pages_file.close
      end

      def title(action, policy = @policy_type, label = @label, date = @date_building)
        [action, policy, label, date].join(" | ")
      end
    end
  end
end