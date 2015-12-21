require_relative '../reporting'
#TODO essayer de fusionner avec statistic.rb
module Tasking
  module Statistic
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


      def max(a, b)
        a > b ? a : b
      end

      def title(action, policy = @policy_type, label = @label, date = @date_building)
        [action, policy, label, date].join(" | ")
      end
    end
  end
end