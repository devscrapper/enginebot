require 'uuid'
require_relative 'page'
module Tasking
  module Visit
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
          new_date = date.is_a?(String) ? Date.parse(date) : date
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

      def initialize(visit, policy_type=nil, advert=nil, device_platform=nil)

        super(visit)
        if advert.nil? and device_platform.nil?
          splitted = visit.split(SEPARATOR1)
          @operating_system = splitted[17]
          @operating_system_version = splitted[18]
          @browser = splitted[19]
          @browser_version = splitted[20]
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
          @type = policy_type
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

      attr :min_count_page_advertiser,
           :max_count_page_advertiser,
           :min_duration_page_advertiser,
           :max_duration_page_advertiser,
           :percent_local_page_advertiser,
           :duration_referral,
           :min_count_page_organic,
           :max_count_page_organic,
           :min_duration_page_organic,
           :max_duration_page_organic,
           :min_duration,
           :max_duration,
           :label_advertisings

      def initialize(visit,
                     min_count_page_advertiser=nil,
                     max_count_page_advertiser=nil,
                     min_duration_page_advertiser=nil,
                     max_duration_page_advertiser=nil,
                     percent_local_page_advertiser=nil,
                     duration_referral=nil,
                     min_count_page_organic=nil,
                     max_count_page_organic=nil,
                     min_duration_page_organic=nil,
                     max_duration_page_organic=nil,
                     min_duration=nil,
                     max_duration=nil,
                     label_advertisings=nil)
        super(visit)
        @min_count_page_advertiser = min_count_page_advertiser
        @max_count_page_advertiser = max_count_page_advertiser
        @min_duration_page_advertiser = min_duration_page_advertiser
        @max_duration_page_advertiser = max_duration_page_advertiser
        @percent_local_page_advertiser = percent_local_page_advertiser
        @duration_referral = duration_referral
        @min_count_page_organic = min_count_page_organic
        @max_count_page_organic = max_count_page_organic
        @min_duration_page_organic = min_duration_page_organic
        @max_duration_page_organic = max_duration_page_organic
        @min_duration = min_duration
        @max_duration = max_duration
        @label_advertisings = label_advertisings
      end

      def to_file
        require 'uuid'
        advertiser_durations_size = Random.rand(@min_count_page_advertiser..@max_count_page_advertiser) unless @advert == "none"

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
                            :advert => @advert == "none" ? {:advertising => @advert.to_sym} : {:advertising => @advert.to_sym,
                                                                                               :advertiser => @advert.to_sym == :adsense ?
                                                                                                   # advert = Adsense
                                                                                                   {:durations => Array.new(advertiser_durations_size).fill { Random.rand(@min_duration_page_advertiser..@max_duration_page_advertiser) }, #calculé par engine_bot
                                                                                                    :arounds => Array.new(advertiser_durations_size).fill(:outside_fqdn).fill(:inside_fqdn, 0, (advertiser_durations_size * @percent_local_page_advertiser/100).round(0))}
                                                                                               : #advert = Adword
                                                                                                   {:label => @label_advertisings, #fourni par statupweb lors de la creation de la policy seaattack
                                                                                                    :durations => Array.new(advertiser_durations_size).fill { Random.rand(@min_duration_page_advertiser..@max_duration_page_advertiser) }, #calculé par engine_bot
                                                                                                    :arounds => Array.new(advertiser_durations_size).fill(:outside_fqdn).fill(:inside_fqdn, 0, (advertiser_durations_size * @percent_local_page_advertiser/100).round(0))}
                            } #calculé par engine_bot
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
            visit[:visit][:referrer][:duration] = @duration_referral
            visit[:visit][:referrer][:random_search] = {:min => @min_duration_page_organic, :max => @max_duration_page_organic}
            visit[:visit][:referrer][:random_surf] = {:min => @min_duration, :max => @max_duration}
            visit[:visit][:referrer][:keyword] = @referral_kw
            visit[:visit][:referrer][:durations] = Array.new(@referral_index_page_results.to_i).fill { Random.rand(@min_duration_page_organic..@max_duration_page_organic) }
            visit[:visit][:referrer][:referral_path] = @referral_path
            visit[:visit][:referrer][:referral_hostname] = @source
            visit[:visit][:referrer][:referral_uri_search] = @referral_uri_search
            visit[:visitor][:browser][:engine_search] = @referral_search_engine.to_sym

          when "organic"
            visit[:visit][:referrer][:medium] = :organic
            visit[:visit][:referrer][:random_search] = {:min => @min_duration_page_organic, :max => @max_duration_page_organic}
            visit[:visit][:referrer][:random_surf] = {:min => @min_duration, :max => @max_duration}
            visit[:visit][:referrer][:keyword] = @keyword
            visit[:visitor][:browser][:engine_search] = @source.to_sym
            visit[:visit][:referrer][:durations] = Array.new(@organic_index_page_results.to_i).fill { Random.rand(@min_duration_page_organic..@max_duration_page_organic) }

        end
        visit
      end

      def to_yaml(*a)
        to_file.to_yaml
      end
    end
  end
end