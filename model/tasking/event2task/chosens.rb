require_relative 'reporting'

module Tasking

  EOFLINE = "\n"


  class Chosen_device_platform
    attr_accessor :count_visits
    attr :browser,
         :browser_version,
         :os,
         :os_version,
         :screen_resolution
    SEPARATOR1=";"

    def initialize(device)
      @browser,
          @browser_version,
          @os,
          @os_version,
          @screen_resolution,
          @count_visits = device.strip.split(SEPARATOR1)
      @count_visits = @count_visits.to_f
    end

    def to_s(*a)
      [
          @browser,
          @browser_version,
          @os,
          @os_version,
          @screen_resolution,
          @count_visits
      ].join(SEPARATOR1)
    end
  end


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

      if direct_medium_percent > 0
        direct_medium_count = (direct_medium_percent * count_visit / 100).to_i

        Choosing_landing_medium_in_mem("direct", direct_medium_count, chosen_landing_pages_file)
      else
        direct_medium_count = 0
      end

      if referral_medium_percent > 0
        referral_medium_count = (referral_medium_percent * count_visit / 100).to_i

        Choosing_landing_medium_in_mem("referral", referral_medium_count, chosen_landing_pages_file)
      else
        referral_medium_count = 0
      end


      organic_medium_count = count_visit - (direct_medium_count + referral_medium_count)
      Choosing_landing_medium_in_mem("organic", organic_medium_count, chosen_landing_pages_file) if organic_medium_count > 0

      chosen_landing_pages_file.close
      chosen_landing_pages_file.archive_previous
      @logger.an_event.debug "Choosing landing pages for <#{@policy_type}> <#{@label}> <#{@date_building}> is over"
    end


    def Choosing_device_platform(count_visits)
      @logger.an_event.debug "Choosing device platform for <#{@policy_type}> <#{@label}> <#{@date_building}> is starting"
      begin
        raise ArgumentError "count_visits is zero" if count_visits == 0

        device_platform = Flow.new(TMP, "device-platform", @policy_type, @label, @date_building).last
        raise IOError "input flow device-platform for <#{@label}> for <#{@date_building}> is missing" if device_platform.nil?

        reporting = Reporting.new(@label, @date_building, @policy_type)

        chosen_device_platform_file = Flow.new(TMP, "chosen-device-platform", @policy_type, @label, @date_building) #output
        total_visits = 0
        pob = ProgressBar.create(:title => title("Choosing device platforme"), :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => count_visits, :format => '%t, %c/%C, %a|%w|')

        device_platform.foreach(EOFLINE) { |device|
          chosen_device = Chosen_device_platform.new(device)
          # en entree la somme des chosen_device.count_visits = 100%
          ################################################################################"
          # IMPORTANT
          # -----------------------------------------------------------------------------
          # max((chosen_device.count_visits * count_visits / 100).to_i + 1 , 1)
          # on ajoute + 1 à la partie entiere pour ne pas avoir un manque de device_platforme en raison des dixièmes qui apparaissent lors de la
          # division par 100.
          # en conséquence il y aura tj plus de device_platform que de visit ; alors les derniers (ceux qui ont peu de visites )
          # device_platforme ne seront jamais utilisés.

          if total_visits < count_visits
            # si chosen_device.count_visits == 0 alors on le remplace par 1 => max()
            count_device = max((chosen_device.count_visits * count_visits / 100).to_i + 1, 1)
            # pour eviter de dépasser le nombre de visite attendues
            count_device = count_visits - total_visits if total_visits + count_device > count_visits
            total_visits += count_device
            count_device.times { chosen_device_platform_file.write("#{chosen_device.to_s}#{EOFLINE}"); pob.increment }
            chosen_device.count_visits = count_device
            reporting.device_platform_obj(chosen_device, count_visits)
          end
        }

        reporting.to_file("device platforme objective")
        chosen_device_platform_file.close
        chosen_device_platform_file.archive_previous
      rescue Exception => e
        @logger.an_event.error "Choosing device platform for <#{@policy_type}> <#{@label}> <#{@date_building}> is over =>  #{e.message}"
      else

        @logger.an_event.debug "Choosing device platform for <#{@policy_type}> <#{@label}> <#{@date_building}> is over"
      end
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

    def max(a, b)
      a > b ? a : b
    end

    def title(action, policy = @policy_type, label = @label, date = @date_building)
      [action, policy, label, date].join(" | ")
    end
  end
end