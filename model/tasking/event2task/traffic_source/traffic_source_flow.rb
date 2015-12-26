module Tasking
  module TrafficSource
    class TrafficSourceFlow
      NOT_SET = "(not set)"
      NONE = "(none)"
      DIRECT = "(direct)"
      ORGANIC = "organic"
      REFERRAL = "referral"
      SEPARATOR = "%SEP%"
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
        to_file.join(SEPARATOR) + "#{EOFLINE}"
      end

    end

    class Traffic_source_direct < TrafficSourceFlow

      attr_accessor :title
      #landing_page file :       hostname;page_path;(not set);(direct);(none);(not set)

      def initialize(page)
        not_use,
            @scheme,
            @hostname,
            @landing_page_path,
            @title = page.split(SEPARATOR)

        raise "traffic source direct malformed" if @scheme.nil? or @hostname.nil? or @landing_page_path.nil? or @title.nil?

        @referral_path = NOT_SET
        @source = DIRECT
        @medium = NONE
        @keyword = NOT_SET
      end

    end

    class Traffic_source_organic < TrafficSourceFlow
      attr :index_page_results #numero de page dans laquelle a été trouvé le landing page path pour ces mot cle (organic)


      def initialize(page)
        # from scraper_bot :
        # [uri.scheme, uri.hostname, uri.path, "(not set)", engine, "organic", kw, index]
        @scheme,
            @hostname,
            @landing_page_path,
            not_use,
            @source,
            not_use,
            @keyword,
            @index_page_results= page.split(SEPARATOR)

        @referral_path = NOT_SET
        @medium = ORGANIC

        raise "traffic source organic malformed" if @scheme.nil? or @hostname.nil? or @landing_page_path.nil? or @source.nil? or @keyword.nil? or @index_page_results.nil?
      end

      #landing_page file :       hostname;landing_page_path;(not set);@source;organic;@keyword;1
      def to_file
        super << @index_page_results
      end
    end

    class Traffic_source_referral < TrafficSourceFlow

      attr :referral_kw, #mot cle pour atterrir sur le referral
           :referral_uri_search, # uri du referral trouver dans la page numero <index> des results de <engine>
           :referral_search_engine, # search engine pour atteindre le referral
           :referral_index_page_results # index de la page result contenant l'uri <referral_uri_search> du referral rechercher avec <referral_kw>  avec le moteur <referral_search_engine>


      def initialize(page)
        @scheme,
            @hostname,
            @landing_page_path,
            @referral_path,
            @source,
            not_use,
            not_use,
            @referral_title,   #TODO supprimer referral_title dans engione_bot
            @referral_kw,
            @referral_uri_search,
            @referral_search_engine,
            @referral_index_page_results = page.split(SEPARATOR)

        @medium = REFERRAL
        @keyword = NOT_SET

        raise "traffic source referral malformed" if @scheme.nil? or @hostname.nil? or @landing_page_path.nil? or @source.nil? or \
       @referral_kw.nil? or @referral_uri_search.nil? or @referral_search_engine.nil? or \
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
end