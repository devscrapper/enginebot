require 'uuid'

module Tasking
  class Visit

    SEPARATOR1="%SEP%"
    EOFLINE="%EOFL%"
    SEPARATOR2=";"
    SEPARATOR4="|"
    SEPARATOR5=","
    SEPARATOR3="!"
    EOFLINE2 ="\n"


    attr :id_visit,
         :label,
         :source,
         :medium,
         :keyword,
         :landing_page_scheme,
         :landing_page_hostname,
         :landing_page_path,
         :pages, # array contenant les pages de la visit. L'objet page ne contient que la duration pour chaque page de la visite ; landing page comprise
         :referral_title,
         :organic_index_page_results, # index de la page result contenant l'uri du landing page
         :referral_kw, #mot cle pour atterrir sur le referral
         :referral_uri_search, # uri du referral trouver dans la page numero <index> des results de <engine>
         :referral_search_engine, # search engine pour atteindre le referral
         :referral_index_page_results # index de la page result contenant l'uri <referral_uri_search> du referral rechercher avec <referral_kw>  avec le moteur <referral_search_engine>


    def initialize(first_page, label=nil, duration=nil)

      #si duration n'est pas nil alors c'est un landing page qui est passé en paramètre, et c'est donc l'intialisation de
      #la visite qui est réalisée dans Building_visit
      #sinon c'est les autres etapes qui par héritage utilise ce consctructeur pour creer une visite
      if duration.nil? and label.nil?
        @id_visit,
            @label,
            @landing_page_scheme,
            @landing_page_hostname,
            @landing_page_path,
            @pages,
            @referral_path,
            @source,
            @medium,
            @keyword,
            @organic_index_page_results,
            @referral_title,
            @referral_kw,
            @referral_uri_search,
            @referral_search_engine,
            @referral_index_page_results = first_page.split(SEPARATOR1)
        @pages = @pages.split(SEPARATOR2).map { |delay| Page.new(delay) }
      else
        @id_visit = UUID.generate
        @label = label
        @pages = [Page.new(duration)]

        case first_page.split(SEPARATOR1)[5]
          when "organic"
            @landing_page_scheme,
            @landing_page_hostname,
                @landing_page_path,
                @referral_path,
                @source,
                @medium,
                @keyword,
                @organic_index_page_results = first_page.split(SEPARATOR1)

            @referral_title = "none"
            @referral_kw ="none"
            @referral_uri_search = "none"
            @referral_search_engine = "none"
            @referral_index_page_results = "none"
          when "referral"
            @landing_page_scheme,
            @landing_page_hostname,
                @landing_page_path,
                @referral_path,
                @source,
                @medium,
                @keyword,
                @referral_title,
                @referral_kw,
                @referral_uri_search,
                @referral_search_engine,
                @referral_index_page_results = first_page.split(SEPARATOR1)
            @organic_index_page_results = "none"
          when "(none)"
            @landing_page_scheme,
            @landing_page_hostname,
                @landing_page_path,
                @referral_path,
                @source,
                @medium,
                @keyword = first_page.split(SEPARATOR1)
            @organic_index_page_results = "none"
            @referral_title = "none"
            @referral_kw ="none"
            @referral_uri_search = "none"
            @referral_search_engine = "none"
            @referral_index_page_results = "none"
          else
            p "medium unknown : #{first_page.split(SEPARATOR1)[4]}"
        end
      end

    end

    def durations
      @pages.map { |p| p.duration }
    end

    def length
      @pages.size
    end

    def bounce?
      length == 1
    end

    def add_page(duration)
      @pages << Page.new(duration)
    end

    def to_file
      [
          @id_visit, #0
          @label, #1
          @landing_page_scheme, #2
          @landing_page_hostname, #3
          @landing_page_path, #4
          @pages.map { |p| p.duration }.join(SEPARATOR2), #5
          @referral_path, #6
          @source, #7
          @medium, #8
          @keyword, #9
          @organic_index_page_results, #10
          @referral_title, #11
          @referral_kw, #12
          @referral_uri_search, #13
          @referral_search_engine, #14
          @referral_index_page_results #15
      ]

    end

    def to_s(*a)
      to_file.join(SEPARATOR1)
    end


  end

  class Planed_visit < Visit

    attr :start_date_time

    def initialize(visit, date=nil, hour=nil)

      super(visit)
      if date.nil? and hour.nil?
        @start_date_time = Time.parse(visit.split(SEPARATOR1)[16])

      else
        new_date = Date.parse(date)
        @start_date_time = Time.new(new_date.year,
                                    new_date.month,
                                    new_date.day,
                                    hour.to_i,
                                    rand(60),
                                    0)
      end

    end

    def to_file
      super << @start_date_time #16
    end


  end

  class Final_visit < Planed_visit


    attr :type, # :traffic pour une visit generant du traffic sans cliquer surune pub
         # :advert pour ine visit generant du traffic avec click sur un pub
         :browser,
         :browser_version,
         :operating_system,
         :operating_system_version,
         :screen_resolution,
         :advert

    def initialize(visit, advert=nil, device_platform=nil)

      super(visit)
      if advert.nil? and device_platform.nil?
        splitted = visit.split(SEPARATOR1)
        @browser = splitted[17]
        @browser_version = splitted[18]
        @operating_system = splitted[19]
        @operating_system_version = splitted[20]
        @screen_resolution = splitted[21]
        @advert = splitted[22]
        @type = splitted[23]
      else
        @browser,
            @browser_version,
            @operating_system,
            @operating_system_version,
            @screen_resolution = device_platform.strip.split(SEPARATOR2)
        @advert = advert
        @type = @advert == "none" ? :traffic : :advert
      end

    end

    def to_file
      super +
          [
              @browser, #17
              @browser_version, #18
              @operating_system, #19
              @operating_system_version, #20
              @screen_resolution, #21
              @advert, #22
              @type, #23
          ]
    end


  end

  class Published_visit < Final_visit
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

    MIN_DURATION_SURF = 5 # temps en seconde min de lecture d'une page d'un site consulté avant d'atterrir sur le website
    MAX_DURATION_SURF = 10 # temps en seconde min de lecture d'une page d'un site consulté avant d'atterrir sur le website

    def initialize(visit)
      super(visit)
    end

    def to_file
      require 'uuid'
      advertiser_durations_size = Random.rand(MIN_COUNT_PAGE_ADVERTISER..MAX_COUNT_PAGE_ADVERTISER) # calculé par engine_bot

      visit = {:visit => {:id => @id_visit,
                          :start_date_time => @start_date_time,
                          :type => @type.to_sym,
                          :landing => {:scheme => @landing_page_scheme,
                                       :fqdn => @landing_page_hostname,
                                       :path => @landing_page_path
                          },
                          :durations => durations,
                          :referrer => {:medium => @medium
                          },
                          :advert => @type.to_sym != :advert ? {:advertising => :none} : {:advertising => @advert.to_sym,
                                                                                          :advertiser => {:durations => Array.new(advertiser_durations_size).fill { Random.rand(MIN_DURATION_PAGE_ADVERTISER..MAX_DURATION_PAGE_ADVERTISER) }, #calculé par engine_bot
                                                                                                          :arounds => Array.new(advertiser_durations_size).fill(:outside_fqdn).fill(:inside_fqdn, 0, (advertiser_durations_size * PERCENT_LOCAL_PAGE_ADVERTISER/100).round(0))} #calculé par engine_bot
                          }
      },
               :website => {:label => @label,
                            #TODO revisier l'initialisation de many_hostname & many_account
                            :many_hostname => :true,
                            :many_account_ga => :no
               },
               :visitor => {
                   :id => UUID.generate,
                   :browser => {:name => @browser,
                                :version => @browser_version,
                                :operating_system => @operating_system,
                                :operating_system_version => @operating_system_version,
                                :screen_resolution => @screen_resolution
                   }
               }

      }


      case visit[:visit][:referrer][:medium]
        when "(none)"
          visit[:visit][:referrer][:medium] = :none
          visit[:visitor][:browser][:engine_search] = :google

        when "referral"
          visit[:visit][:referrer][:medium] = :referral
          visit[:visit][:referrer][:duration] = DURATION_REFERRAL
          visit[:visit][:referrer][:random_search] = {:min => MIN_DURATION_PAGE_ORGANIC, :max => MAX_DURATION_PAGE_ORGANIC}
          visit[:visit][:referrer][:random_surf] = {:min => MIN_DURATION_SURF, :max => MAX_DURATION_SURF}
          visit[:visit][:referrer][:keyword] = @referral_kw
          visit[:visit][:referrer][:durations] = Array.new(@referral_index_page_results.to_i).fill { Random.rand(MIN_DURATION_PAGE_ORGANIC..MAX_DURATION_PAGE_ORGANIC) }
          visit[:visit][:referrer][:referral_path] = @referral_path
          visit[:visit][:referrer][:referral_hostname] = @source
          visit[:visit][:referrer][:duration] = DURATION_REFERRAL
          visit[:visit][:referrer][:referral_uri_search] = @referral_uri_search
          visit[:visitor][:browser][:engine_search] = @referral_search_engine.to_sym

        when "organic"
          visit[:visit][:referrer][:medium] = :organic
          visit[:visit][:referrer][:random_search] = {:min => MIN_DURATION_PAGE_ORGANIC, :max => MAX_DURATION_PAGE_ORGANIC}
          visit[:visit][:referrer][:random_surf] = {:min => MIN_DURATION_SURF, :max => MAX_DURATION_SURF}
          visit[:visit][:referrer][:keyword] = @keyword
          visit[:visitor][:browser][:engine_search] = @source.to_sym
          visit[:visit][:referrer][:durations] = Array.new(@organic_index_page_results.to_i).fill { Random.rand(MIN_DURATION_PAGE_ORGANIC..MAX_DURATION_PAGE_ORGANIC) }

      end
      visit
    end

    def to_yaml(*a)
      to_file.to_yaml
    end
  end
end