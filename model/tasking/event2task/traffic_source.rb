module Tasking

  class Traffic_source
    NOT_SET = "(not set)"
    NONE = "(none)"
    DIRECT = "(direct)"
    ORGANIC = "organic"
    REFERRAL = "referral"
    attr :scheme,
         :hostname,
         :landing_page_path,
         :referral_path,
         :source,
         :medium,
         :keyword

    def to_file
      [
          @scheme,
          @hostname,
          @landing_page_path,
          @referral_path,
          @source,
          @medium,
          @keyword
      ]
    end

    def to_s(*a)
      to_file.join(SEPARATOR1) + "#{EOFLINE}"
    end

  end

  class Traffic_source_direct < Traffic_source

    attr_accessor :title

    #landing_page file :       hostname;page_path;(not set);(direct);(none);(not set)

    def initialize(page)
      @scheme,
          @hostname,
          @landing_page_path,
          @title = page.split(SEPARATOR1)

      raise "traffic source direct malformed" if @hostname.nil? or @landing_page_path.nil? or @title.nil?

      @referral_path = NOT_SET
      @source = DIRECT
      @medium = NONE
      @keyword = NOT_SET
    end

  end

  class Traffic_source_organic < Traffic_source
    attr :index_page_results #numero de page dans laquelle a été trouvé le landing page path pour ces mot cle (organic)


    def initialize(page)
      # from scraper_bot :
      # [uri.hostname, uri.path, "(not set)", engine, "organic", kw, index]

      @hostname,
          @landing_page_path,
          not_use,
          @source,
          not_use,
          @keyword,
          @index_page_results= page.split(SEPARATOR2)

      @referral_path = NOT_SET
      @medium = ORGANIC

      raise "traffic source organic malformed" if @hostname.nil? or @landing_page_path.nil? or @source.nil? or @keyword.nil? or @index_page_results.nil?
    end

    #landing_page file :       hostname;landing_page_path;(not set);@source;organic;@keyword;1
    def to_file
      super << @index_page_results
    end
  end

  class Traffic_source_referral < Traffic_source

    attr :referral_kw, #mot cle pour atterrir sur le referral
         :referral_uri_search, # uri du referral trouver dans la page numero <index> des results de <engine>
         :referral_search_engine, # search engine pour atteindre le referral
         :referral_index_page_results # index de la page result contenant l'uri <referral_uri_search> du referral rechercher avec <referral_kw>  avec le moteur <referral_search_engine>


    def initialize(page)
      @hostname,
          @landing_page_path,
          @referral_path,
          @source,
          not_use,
          not_use,
          @referral_title,
          @referral_kw,
          @referral_uri_search,
          @referral_search_engine,
          @referral_index_page_results = page.split(SEPARATOR2)

      @medium = REFERRAL
      @keyword = NOT_SET

      raise "traffic source referral malformed" if @hostname.nil? or @landing_page_path.nil? or @source.nil? or \
      @referral_title.nil? or @referral_kw.nil? or @referral_uri_search.nil? or @referral_search_engine.nil? or \
      @referral_index_page_results.nil? or @referral_path.nil?
    end

    #landing_page file :       hostname;landing_page_path;@referral_path;@source;referral;(not set);@referral_title;@referral_kw;@referral_uri_search;@referral_search_engine;@referral_index_page_results
    def to_file

      super + [
          @referral_title,
          @referral_kw,
          @referral_uri_search,
          @referral_search_engine,
          @referral_index_page_results
      ]

    end
  end
end