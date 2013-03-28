module Tasking
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

    def initialize(device)
      splitted_device = device.strip.split(SEPARATOR2)
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
      "#{@browser}#{SEPARATOR2}#{@browser_version}#{SEPARATOR2}#{@os}#{SEPARATOR2}#{@os_version}#{SEPARATOR2}#{@flash_version}#{SEPARATOR2}#{@java_enabled}#{SEPARATOR2}#{@screen_colors}#{SEPARATOR2}#{@screen_resolution}"
    end
  end

  class Chosen

    def Choosing_landing_pages(label, date, direct_medium_percent, organic_medium_percent, referral_medium_percent, count_visit)
      information("Choosing landing pages for #{label} for #{date} is starting")
      p 0
      file = Flow.new(TMP, "chosen-landing-pages", label, date)
      p 1
      file.delete if file.exist?
      p 2
      result = Choosing_landing(label, date, "direct", direct_medium_percent, count_visit) &&
          Choosing_landing(label, date, "referral", referral_medium_percent, count_visit) &&
          Choosing_landing(label, date, "organic", organic_medium_percent, count_visit)
      p 3
      alert("Choosing landing pages for #{label} fails because inputs Landing files are missing") unless result
      information("Choosing landing pages for #{label} is over")
    end


    def Choosing_device_platform(label, date, count_visits)
      #TODO valider les flows
      information("Choosing device platform for #{label} for #{date} is starting")

      device_platform = Flow.from_basename(TMP, Flow.new(TMP, "device-platform", label, date).last)

      if device_platform.nil?
        alert("Choosing_device_platform for #{label} fails because inputs #{device_platform.basename} file for #{label} in date of #{date} is missing")
        return false
      end
      p "-1"
      chosen_device_platform_file = Flow.new(TMP, "chosen-device-platform", label, date)
      total_visits = 0
      p 0
      pob = ProgressBar.create(:title => File.basename(device_platform), :length => 180, :starting_at => 0, :total => count_visits, :format => '%t, %c/%C, %a|%w|')
      begin
        IO.foreach(device_platform, EOFLINE2, encoding: "BOM|UTF-8:-") { |device|
          p 1
          chosen_device = Chosen_device_platform.new(device)
          p 2
          count_device = Common.max((chosen_device.count_visits * count_visits / 100).to_i, 1)
          count_device = count_visits - total_visits if total_visits + count_device > count_visits # pour eviter de peasser le nombre de visite attendues
          total_visits += count_device
          count_device.times { chosen_device_platform_file.write("#{chosen_device.to_s}#{EOFLINE2}"); pob.increment }

        }
      rescue Exception => e
        error(e.message)
      end
      chosen_device_platform_file.close
      #TODO valider l'archivage du vieux fichier
      chosen_device_platform_file.archive
      information("Choosing device platform for #{label} is over")
    end

    #private
    def Choosing_landing(label, date, medium_type, medium_percent, count_visit)
      #TODO valider la moe des flow
      landing_pages_file = Flow.from_basename(TMP, Flow.new(TMP, "landing-pages-#{medium_type}", label, date).last)
      medium_count = (medium_percent * count_visit / 100).to_i
      landing_pages_file_lines = landing_pages_file.count_lines(EOFLINE2)
      chosen_landing_pages_file = Flow.new(TMP, "chosen-landing-pages", label, date)
      p landing_pages_file
      p = ProgressBar.create(:title => "#{medium_type} landing pages", :length => 180, :starting_at => 0, :total => medium_count, :format => '%t, %c/%C, %a|%w|')
      p 1
      while medium_count > 0 and landing_pages_file_lines > 0
        p 2
        chose = rand(landing_pages_file_lines - 1) + 1
        p 3
        landing_pages_file.rewind
        p 4
        (chose - 1).times { landing_pages_file.readline(EOFLINE2) }
        p 5
        page = landing_pages_file.readline(EOFLINE2)
        p 6
        chosen_landing_pages_file.append(page)
        p 7
        medium_count -= 1
        p.increment
      end

      chosen_landing_pages_file.close
      landing_pages_file.close
      #TODO valider archivage des vieux fichiers
      chosen_landing_pages_file.archive
      true
    end
  end
end