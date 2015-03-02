require 'uuid'

module Building
  class Visit

    SEPARATOR="%SEP%"
    EOFLINE="%EOFL%"
    SEPARATOR2=";"
    SEPARATOR4="|"
    SEPARATOR5=","
    SEPARATOR3="!"
    EOFLINE2 ="\n"


    attr :id_visit,
         :start_date_time,
         :return_visitor,
         :browser,
         :browser_version,
         :operating_system,
         :operating_system_version,
         :flash_version,
         :java_enabled,
         :screens_colors,
         :screen_resolution,
         :source,
         :medium,
         :keyword,
         :pages,
         :advert,
         :index_page_results

    def initialize(first_page, duration)
      @id_visit = UUID.generate
      splitted_page = first_page.split(SEPARATOR2)
      @referral_path = splitted_page[1].strip
      @source = splitted_page[2].strip
      @medium = splitted_page[3].strip
      @keyword = splitted_page[4].strip
      case @medium
        when "organic"
          @index_page_results = splitted_page[5].to_i
        when "(none)"  , "referral"
          @index_page_results = "none"
        else
          p "medium unknown : #{@medium}"
      end

      @pages = [Page.new("#{splitted_page[0]}#{SEPARATOR4}#{duration}")]
    end

    def length
      @pages.size
    end

    def bounce?
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
      visit += "#{SEPARATOR2}#{@index_page_results}" unless  @index_page_results.nil?
      visit += "#{SEPARATOR2}#{@advert}" unless @advert.nil?
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
      @index_page_results = splitted_visit[5]
      @pages = []
      splitted_visit[6].split(SEPARATOR3).each { |page| @pages << Page.new(page) }
    end

  end

  class Final_visit < Planed_visit

    def initialize(visit, return_visitor, advert, pages, device_platform)
      splitted_visit = visit.split(SEPARATOR2)

      @id_visit = splitted_visit[0].strip
      @start_date_time = splitted_visit[1].strip
      @return_visitor = return_visitor
      @referral_path = splitted_visit[2].strip
      @source = splitted_visit[3].strip
      @medium = splitted_visit[4].strip
      @keyword = splitted_visit[5].strip
      @pages = []
      @index_page_results = splitted_visit[6]
      splitted_visit[7].strip.split(SEPARATOR3).each { |page|
        p = Page.new(page)
        p.set_properties(pages)
        @pages << p
      }

      splitted_device_platform = device_platform.strip.split(SEPARATOR2)
      @browser = splitted_device_platform[0]
      @browser_version = splitted_device_platform[1]
      @operating_system = splitted_device_platform[2]
      @operating_system_version = splitted_device_platform[3]
      @flash_version = splitted_device_platform[4]
      @java_enabled = splitted_device_platform[5]
      @screens_colors = splitted_device_platform[6]
      @screen_resolution = splitted_device_platform[7]
      @advert = advert
    end
  end

  class Published_visit < Visit

    #TODO meo ces données dans statupweb
    MIN_COUNT_PAGE_ADVERTISER = 10 # nombre de page min consultées chez l'advertiser : fourni par statupweb
    MAX_COUNT_PAGE_ADVERTISER = 15 # nombre de page max consultées chez l'advertiser : fourni par statupweb
    MIN_DURATION_PAGE_ADVERTISER = 60 # durée de lecture min d'une page max consultées chez l'advertiser : fourni par statupweb
    MAX_DURATION_PAGE_ADVERTISER = 120 # durée de lecture max d'une page max consultées chez l'advertiser : fourni par statupweb
    PERCENT_LOCAL_PAGE_ADVERTISER = 80 # pourcentage de page consultées localement à l'advertiser fournit par statupweb
    DURATION_REFERRAL = 20 # durée de lecture du referral : fourni par statupweb
    MIN_COUNT_PAGE_ORGANIC = 4 #nombre min de page de resultat du moteur de recherche consultées : fourni par statupweb
    MAX_COUNT_PAGE_ORGANIC = 6 #nombre min de page de resultat du moteur de recherche consultées : fourni par statupweb
    MIN_DURATION_PAGE_ORGANIC = 10 #durée de lecture min d'une page de resultat fourni par le moteur de recherche : fourni par statupweb
    MAX_DURATION_PAGE_ORGANIC = 30 #durée de lecture max d'une page de resultat fourni par le moteur de recherche : fourni par statupweb

    def initialize(visit)

      splitted_visit = visit.strip.split(SEPARATOR2)
      @id_visit = splitted_visit[0]
      @start_date_time = Time.parse(splitted_visit[1])
      @return_visitor = splitted_visit[2]
      @browser = splitted_visit[3]
      @browser_version = splitted_visit[4]
      @operating_system = splitted_visit[5]
      @operating_system_version = splitted_visit[6]
      @flash_version = splitted_visit[7]
      @java_enabled = splitted_visit[8]
      @screens_colors = splitted_visit[9]
      @screen_resolution = splitted_visit[10]
      @referral_path = splitted_visit[11]
      @source = splitted_visit[12]
      @medium = splitted_visit[13]
      @keyword = splitted_visit[14]

      @index_page_results = splitted_visit[15]
      @advert = splitted_visit[16]
      @pages = []
      splitted_visit[17].strip.split(SEPARATOR3).each { |page|
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
       "index_page_results" => @index_page_results,
       "pages" => @pages,
       "advert" => @advert
      }.to_json(*a)
    end

    # prend en entree un flux json qui décrit la visit
    # retour un flux yaml qui définit la visit au format attendu par visitor_bot
    def generate_output(label)
      require 'uuid'
      advertiser_durations_size = Random.rand(MIN_COUNT_PAGE_ADVERTISER..MAX_COUNT_PAGE_ADVERTISER) # calculé par engine_bot

      visit = {:id_visit => @id_visit,
               :start_date_time => @start_date_time,
               :durations => @pages.map { |page| page.generate_output },
               :website => {:label => label,
                            #TODO revisier l'initialisation de many_hostname & many_account
                            :many_hostname => :true,
                            :many_account_ga => :no},
               :visitor => {:return_visitor => @return_visitor == "yes" ? :true : :false,
                            :id => UUID.generate,
                            :browser => {:name => @browser,
                                         :version => @browser_version,
                                         :operating_system => @operating_system,
                                         :operating_system_version => @operating_system_version,
                                         :flash_version => @flash_version,
                                         :java_enabled => @java_enabled,
                                         :screens_colors => @screens_colors,
                                         :screen_resolution => @screen_resolution
                            }
               },
               :referrer => {:referral_path => @referral_path,
                             :source => @source,
                             :medium => @medium,
                             :keyword => @keyword
               },
               :landing => {:fqdn => @pages[0].hostname,
                            :page_path => @pages[0].page_path
               },
               :advert => @advert == "none" ? {:advertising => :none} : {:advertising => @advert.to_sym,
                                                                         :advertiser => {:durations => Array.new(advertiser_durations_size).fill { Random.rand(MIN_DURATION_PAGE_ADVERTISER..MAX_DURATION_PAGE_ADVERTISER) }, #calculé par engine_bot
                                                                                         :arounds => Array.new(advertiser_durations_size).fill(:outside_fqdn).fill(:inside_fqdn, 0, (advertiser_durations_size * PERCENT_LOCAL_PAGE_ADVERTISER/100).round(0))} #calculé par engine_bot
               }
      }

      case visit[:referrer][:medium]
        when "(none)"
        when "referral"
          visit[:referrer][:duration] = DURATION_REFERRAL
        when "organic"
          visit[:referrer][:durations] = Array.new(@index_page_results.to_i).fill { Random.rand(MIN_DURATION_PAGE_ORGANIC..MAX_DURATION_PAGE_ORGANIC) }
          #genere un tableau de mot clé pour pallier à l'échec des recherches et mieux simuler le comportement
          #TODO le comportement est basic, il devra etre enrichi pour mieux simuler un comportement naturel et mettre en dernier ressort les mots du title
          #TODO penser egalement à produire des search qui n'aboutissent jamais dans le engine bot en fonction dun poourcentage determiner par statupweb
          #supprimer les not provide retourner par google
          if visit[:referrer][:keyword] != "(not set)" and
              visit[:referrer][:keyword] != "" and
              visit[:referrer][:keyword] != "(not provided)"
            visit[:referrer][:keyword] = [visit[:referrer][:keyword], @pages[0].title]
          else
            visit[:referrer][:keyword] = [@pages[0].title]
          end

      end
      visit
    end


  end
end