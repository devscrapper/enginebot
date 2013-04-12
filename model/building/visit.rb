module Building
  class Visit

    SEPARATOR="%SEP%"
    EOFLINE="%EOFL%"
    SEPARATOR2=";"
    SEPARATOR4="|"
    SEPARATOR5=","
    SEPARATOR3="!"
    EOFLINE2 ="\n"
    @@count_visit = 0

    attr :id_visit,
         :start_date_time,
         :account_ga,
         :return_visitor,
         :browser,
         :browser_version,
         :operating_system,
         :operating_system_version,
         :flash_version,
         :java_enabled,
         :screens_colors,
         :screen_resolution,
         :pages

    def initialize(first_page, duration)
      @@count_visit += 1
      @id_visit = @@count_visit
      splitted_page = first_page.split(SEPARATOR2)
      @referral_path = splitted_page[1].strip
      @source = splitted_page[2].strip
      @medium = splitted_page[3].strip
      @keyword = splitted_page[4].strip
      @pages = [Page.new("#{splitted_page[0]}#{SEPARATOR4}#{duration}")]
    end

    def length()
      @pages.size
    end

    def bounce?()
      length == 1
    end

    def landing_page
      @pages[0].id_uri
    end

    def add_page(id_uri, duration)
      @pages << Page.new("#{id_uri}#{SEPARATOR4}#{duration}")
    end

    def to_s(*a)
      visit = "#{@id_visit}"
      visit += "#{SEPARATOR2}#{@start_date_time}" unless @start_date_time.nil?
      visit += "#{SEPARATOR2}#{@account_ga}" unless @account_ga.nil?
      visit += "#{SEPARATOR2}#{@return_visitor}" unless @return_visitor.nil?
      visit += "#{SEPARATOR2}#{@browser}" unless @browser.nil?
      visit += "#{SEPARATOR2}#{@browser_version}" unless @browser_version.nil?
      visit += "#{SEPARATOR2}#{@operating_system}" unless @operating_system.nil?
      visit += "#{SEPARATOR2}#{@operating_system_version}" unless @operating_system_version.nil?
      visit += "#{SEPARATOR2}#{@flash_version}" unless @flash_version.nil?
      visit += "#{SEPARATOR2}#{@java_enabled}" unless @java_enabled.nil?
      visit += "#{SEPARATOR2}#{@screens_colors}" unless @screens_colors.nil?
      visit += "#{SEPARATOR2}#{@screen_resolution}" unless @screen_resolution.nil?
      visit += "#{SEPARATOR2}#{@referral_path}" unless @referral_path.nil?
      visit += "#{SEPARATOR2}#{@source}" unless @source.nil?
      visit += "#{SEPARATOR2}#{@medium}" unless @medium.nil?
      visit += "#{SEPARATOR2}#{@keyword}" unless @keyword.nil?
      if !@pages.nil?
        pages = "#{SEPARATOR2}"
        @pages.map { |page| pages += "#{page.to_s}#{SEPARATOR3}" }
        pages = pages.chop if pages[pages.size - 1] == SEPARATOR3
        visit += pages
      end
      visit
    end


  end

  class Planed_visit < Visit

    def initialize(visit, date, hour)
      splitted_visit = visit.strip.split(SEPARATOR2)
      @id_visit = splitted_visit[0]
      new_date = Date.parse(date)

      @start_date_time = Time.new(new_date.year,
                                  new_date.month,
                                  new_date.day,
                                  hour.to_i,
                                  rand(60),
                                  0)
      @referral_path = splitted_visit[1]
      @source = splitted_visit[2]
      @medium = splitted_visit[3]
      @keyword = splitted_visit[4]
      @pages = []
      splitted_visit[5].split(SEPARATOR3).each { |page| @pages << Page.new(page) }
    end

  end

  class Final_visit < Planed_visit

    def initialize(visit, account_ga, return_visitor, pages_file, device_platform)
      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
      splitted_visit = visit.split(SEPARATOR2)

      @id_visit = splitted_visit[0].strip
      @start_date_time = splitted_visit[1].strip
      @account_ga = account_ga
      @return_visitor = return_visitor
      @referral_path = splitted_visit[2].strip
      @source = splitted_visit[3].strip
      @medium = splitted_visit[4].strip
      @keyword = splitted_visit[5].strip
      @pages = []
      #TODO corriger le bug ????????????????
      @logger.an_event.debug splitted_visit
      splitted_visit[6].strip.split(SEPARATOR3).each { |page|
        p = Page.new(page)
        @logger.an_event.debug p
        p.set_properties(pages_file)
        @logger.an_event.debug p
        @pages << p
      }
      @logger.an_event.debug device_platform
      splitted_device_platform = device_platform.strip.split(SEPARATOR2)
      @browser = splitted_device_platform[0]
      @browser_version = splitted_device_platform[1]
      @operating_system = splitted_device_platform[2]
      @operating_system_version = splitted_device_platform[3]
      @flash_version = splitted_device_platform[4]
      @java_enabled = splitted_device_platform[5]
      @screens_colors = splitted_device_platform[6]
      @screen_resolution = splitted_device_platform[7]

    end
  end

  class Published_visit < Visit
    def initialize(visit)
      splitted_visit = visit.strip.split(SEPARATOR2)
      @id_visit = splitted_visit[0]
      @start_date_time = splitted_visit[1]
      @account_ga = splitted_visit[2]
      @return_visitor = splitted_visit[3]
      @browser = splitted_visit[4]
      @browser_version = splitted_visit[5]
      @operating_system = splitted_visit[6]
      @operating_system_version = splitted_visit[7]
      @flash_version = splitted_visit[8]
      @java_enabled = splitted_visit[9]
      @screens_colors = splitted_visit[10]
      @screen_resolution = splitted_visit[11]
      @referral_path = splitted_visit[12]
      @source = splitted_visit[13]
      @medium = splitted_visit[14]
      @keyword = splitted_visit[15]

      @pages = []
      splitted_visit[16].strip.split(SEPARATOR3).each { |page|
        p = Page.new(page)
        splitted_page = page.split(SEPARATOR4)
        p.hostname=splitted_page[2]
        p.page_path=splitted_page[3]
        p.title=splitted_page[4]
        @pages << p
      }

    end


    def to_json(*a)
      {"id_visit" => @id_visit,
       "start_date_time" => @start_date_time,
       "account_ga" => @account_ga,
       "return_visitor" => @return_visitor,
       "browser" => @browser,
       "browser_version" => @browser_version,
       "operating_system" => @operating_system,
       "operating_system_version" => @operating_system_version,
       "flash_version" => @flash_version,
       "java_enabled" => @java_enabled,
       "screens_colors" => @screens_colors,
       "screen_resolution" => @screen_resolution,
       "referral_path" => @referral_path,
       "source" => @source,
       "medium" => @medium,
       "keyword" => @keyword,
       "pages" => @pages
      }.to_json(*a)
    end

  end
end