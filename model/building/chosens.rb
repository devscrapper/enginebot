module Building

  EOFLINE ="\n"
  PROGRESS_BAR_SIZE = 180

  class Chosen_device_platform
    attr_accessor :count_visits
    attr :browser,
         :browser_version,
         :os,
         :os_version,
         :flash_version,
         :java_enabled,
         :screen_colors,
         :screen_resolution
    SEPARATOR1=";"

    def initialize(device)
      splitted_device = device.strip.split(SEPARATOR1)
      @browser = splitted_device[0]
      @browser_version = splitted_device[1]
      @os = splitted_device[2]
      @os_version = splitted_device[3]
      @flash_version = splitted_device[4]
      @java_enabled = splitted_device[5]
      @screen_colors = splitted_device[6]
      @screen_resolution = splitted_device[7]
      @count_visits = splitted_device[8].to_f
    end

    def to_s(*a)
      "#{@browser}#{SEPARATOR1}#{@browser_version}#{SEPARATOR1}#{@os}#{SEPARATOR1}#{@os_version}#{SEPARATOR1}#{@flash_version}#{SEPARATOR1}#{@java_enabled}#{SEPARATOR1}#{@screen_colors}#{SEPARATOR1}#{@screen_resolution}"
    end
  end


  class Chosens
    TMP = File.dirname(__FILE__) + "/../../tmp"

    def initialize()
      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
    end

    def Choosing_landing_pages(label, date, direct_medium_percent, organic_medium_percent, referral_medium_percent, count_visit)
      @logger.an_event.info "Choosing landing pages for #{label} for #{date} is starting"

      Flow.new(TMP, "chosen-landing-pages", label, date).delete
      chosen_landing_pages_file = Flow.new(TMP, "chosen-landing-pages", label, date) #output

      medium_count = (direct_medium_percent * count_visit / 100).to_i
      @logger.an_event.debug "count direct medium #{medium_count}"
      Choosing_landing_medium(label, date, "direct", medium_count, chosen_landing_pages_file)

      medium_count = (referral_medium_percent * count_visit / 100).to_i
      @logger.an_event.debug "count referral medium #{medium_count}"
      Choosing_landing_medium(label, date, "referral", medium_count, chosen_landing_pages_file)

      medium_count = count_visit - ((direct_medium_percent * count_visit / 100).to_i + (referral_medium_percent * count_visit / 100).to_i)
      @logger.an_event.debug "count organic medium #{medium_count}"
      Choosing_landing_medium(label, date, "organic", medium_count, chosen_landing_pages_file)

      chosen_landing_pages_file.close
      chosen_landing_pages_file.archive_previous
      @logger.an_event.info "Choosing landing pages for #{label} is over"
    end


    def Choosing_device_platform(label, date, count_visits)
      @logger.an_event.info "Choosing device platform for #{label} for #{date} is starting"
      begin
        device_platform = Flow.new(TMP, "device-platform", label, date).last
        raise IOError "input flow device-platform for <#{label}> for <#{date}> is missing" if device_platform.nil?

        chosen_device_platform_file = Flow.new(TMP, "chosen-device-platform", label, date) #output
        total_visits = 0
        pob = ProgressBar.create(:title => device_platform.basename, :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => count_visits, :format => '%t, %c/%C, %a|%w|')

        device_platform.foreach(EOFLINE) { |device|
          chosen_device = Chosen_device_platform.new(device)
          count_device = max((chosen_device.count_visits * count_visits / 100).to_i, 1)
          count_device = count_visits - total_visits if total_visits + count_device > count_visits # pour eviter de passer le nombre de visite attendues
          total_visits += count_device
          count_device.times { chosen_device_platform_file.write("#{chosen_device.to_s}#{EOFLINE}"); pob.increment }
        }

        chosen_device_platform_file.archive_previous
      rescue Exception => e
        @logger.an_event.debug e
        @logger.an_event.error "cannot chose device platform for #{label}"
      end
      chosen_device_platform_file.close
      @logger.an_event.info "Choosing device platform for #{label} is over"
    end

    private
    def Choosing_landing_medium(label, date, medium_type, medium_count, chosen_landing_pages_file)
      # ouverture du dernier fichier créé
      begin
        landing_pages_file = Flow.new(TMP, "landing-pages-#{medium_type}", label, date).last
        raise IOError, "tmp flow landing-pages-#{medium_type} for <#{label}> for <#{date}> is missing" if landing_pages_file.nil?

        landing_pages_file_lines = landing_pages_file.count_lines(EOFLINE)
        p = ProgressBar.create(:title => "#{medium_type} landing pages", :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => medium_count, :format => '%t, %c/%C, %a|%w|')
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
        @logger.an_event.error "cannot chose landing page of medium <#{medium_type}> for #{label}"
        @logger.an_event.debug e
      end
      landing_pages_file.close
    end

    def max(a, b)
      a > b ? a : b
    end
  end
end