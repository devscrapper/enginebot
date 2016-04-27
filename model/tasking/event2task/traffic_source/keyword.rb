#encoding:utf-8
require 'i18n'
require 'net/http'
require 'addressable/uri'
require 'open-uri'
require 'thwait'
require 'yaml'
require 'json'
require_relative '../../../../lib/parameter'
require_relative '../../../../lib/error'


module Tasking
  module TrafficSource
    class Keyword
      include Errors
      include Addressable
      ARGUMENT_NOT_DEFINE = 1500
      KEYWORD_NOT_SUGGESTED = 1503
      KEYWORD_NOT_EVALUATED = 1504
      KEYWORD_NOT_SCRAPED = 1506

      EOFLINE = "\n"
      SEPARATOR = ";"


      attr_reader :logger,
                  :words, #string of word
                  :engines # hash contenant par engine l'url et l'index de la page dans laquelle le domain a Ã©tÃ© trouvÃ©


      #----------------------------------------------------------------------------------------------------------------
      # sinitialize(words, url="", domain="", index="")
      #----------------------------------------------------------------------------------------------------------------
      # crÃ©Ã© un objet Keyword :
      # - soit Ã  partir d'une chaine validant la regexp
      # - soit Ã  partir des valeurs du mot clÃ©
      #----------------------------------------------------------------------------------------------------------------
      # input :
      # words : list de mots constituant le Keyword ou bien une chaine contenant une mise Ã  plat sous format string au moyen
      # de self.to_s
      # url : l'url recherchÃ©e par les mots (mot issus semrush)
      # domain : le domain recherchÃ© par les mots (mots issus de Google Suggest)
      # index : list des index de page pour les engine pourlesques la recherche estun succes
      #----------------------------------------------------------------------------------------------------------------
      #----------------------------------------------------------------------------------------------------------------
      def initialize(words)

        raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "words"}) if words.nil? or words.empty?

        @words = words.strip
        @engines = {}
        @logger = Keyword.init_logging
      end

      def self.scrape_as_saas(hostname, opts={})
        init_logging
        #"www.epilation-laser-definitive.info"
        type_proxy = nil
        proxy = nil
        keywords = ""
        keywords_io = nil

        keywords_f = opts.fetch(:scraped_f, nil)
        @logger.an_event.debug "keywords flow #{keywords_f}"

        range = opts.fetch(:range, :full)
        @logger.an_event.debug "range data #{range}"


        try_count = 3
        begin
          parameters = Parameter.new(__FILE__)
          saas_host = parameters.saas_host.to_s
          saas_port = parameters.saas_port.to_s
          time_out = parameters.time_out_saas_scrape.to_i

          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "hostname"}) if hostname.nil? or hostname.empty?
          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "saas_host"}) if saas_host.nil? or saas_host.empty?
          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "saas_port"}) if saas_port.nil? or saas_port.empty?
          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "time_out_saas_scrape"}) if time_out.nil? or time_out == 0

          #query http vers keywords saas
          href = URI.encode("http://#{saas_host}:#{saas_port}/?action=scrape&hostname=#{hostname}")
          @logger.an_event.debug "uri scrape_saas : #{href}"

          keywords_io = open(href,
                             "r:utf-8",
                             {:read_timeout => time_out})

        rescue Exception => e
          @logger.an_event.warn "try #{try_count} scrape keywords as saas for #{hostname} : #{e.message}"
          sleep 5
          try_count -= 1
          retry if try_count > 0
          @logger.an_event.error "scrape keywords as saas for #{hostname} : #{e.message}"
          raise Error.new(KEYWORD_NOT_SCRAPED, :values => {:hostname => hostname}, :error => e)

        else
          if keywords_f.nil?
            keywords = keywords_io.read
            @logger.an_event.debug "lecture du fichier csv et rangement dans string"
            if range == :full
              #String
              # tout le contenu
              keywords

            else
              #Array
              #select url & keywords colonne
              keywords_arr = []

              CSV.parse(keywords,
                        {headers: true,
                         converters: :numeric,
                         header_converters: :symbol}).each { |row|
                keywords_arr << [row[:url], row[:keyword]] if !row[:url].nil? and !row[:keyword].nil?
              }
              keywords_arr
            end
          else

            if range == :full
              #File
              FileUtils.cp(keywords_io,
                           keywords_f)
              @logger.an_event.debug "copy du fichier csv dans flow #{keywords_f}"

            else
              #File
              #select url & keywords colonne
              keywords_f = File.open(keywords_f, "w+:bom|utf-8")
              CSV.open(keywords_io,
                       "r:bom|utf-8",
                       {headers: true,
                        converters: :numeric,
                        header_converters: :symbol}).map.each { |row|
                keywords_f.write("#{[row[:url], row[:keyword]].join(SEPARATOR)}#{EOFLINE}")
              }
            end


          end

        ensure


        end
      end




      #----------------------------------------------------------------------------------------------------------------
      # suggest(engine, keyword, domain, driver)
      #----------------------------------------------------------------------------------------------------------------
      # fournit la liste des suggestions d'un mot clÃ© pour une engine
      #----------------------------------------------------------------------------------------------------------------
      # input :
      # un moteur de recherche
      # un mot clÃ©
      # un domaine sans http
      # une instance de webdriver
      # en options :
      # un nom absolu de fichier pour stocker les couples [landing_link, keywords] ; aucun tableau ne sera fournit en Output
      # output :
      # un tableau dont chaque occurence contient le couple [landing_link, keywords]
      # nom absolu de fichier passÃ© en input contenant les donnÃ©es issues de semtush en l'Ã©tat
      #----------------------------------------------------------------------------------------------------------------
      # soit on retourne un tableau de mot clÃ©, soit un flow conte
      #----------------------------------------------------------------------------------------------------------------
      def self.suggest_as_saas(keyword)
        init_logging


        try_count = 3
        suggesteds = []
        begin
          parameters = Parameter.new(__FILE__)
          saas_host = parameters.saas_host.to_s
          saas_port = parameters.saas_port.to_s
          time_out = parameters.time_out_saas_suggest.to_i
          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "keywords"}) if keyword.nil? or keyword.empty?
          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "saas_host"}) if saas_host.nil? or saas_host.empty?
          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "saas_port"}) if saas_port.nil? or saas_port.empty?
          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "time_out_saas_suggest"}) if time_out.nil? or time_out == 0


          #query http vers keywords saas
          href = URI.encode("http://#{saas_host}:#{saas_port}/?action=suggest&keywords=#{keyword}")
          @logger.an_event.debug "uri suggest_saas : #{href}"

          keywords_io = open(href,
                             "r:utf-8",
                             {:read_timeout => time_out})

        rescue Exception => e
          @logger.an_event.warn "suggest keywords as saas for #{keyword} : #{e.message}"
          sleep 5
          try_count -= 1
          retry if try_count > 0
          @logger.an_event.error "suggest keywords as saas for #{keyword} : #{e.message}"
          raise Error.new(KEYWORD_NOT_SUGGESTED, :values => {:hostname => keyword}, :error => e)
          suggesteds

        else
          suggesteds = JSON.parse(keywords_io.string)
          @logger.an_event.debug "suggested keywords as saas for #{keyword} : #{suggesteds}"

          suggesteds
        end


      end

      #----------------------------------------------------------------------------------------------------------------
      # evaluate(domain)
      #----------------------------------------------------------------------------------------------------------------
      # fournit la liste des mots cles d'un domaine au moyen de semrush.com
      #----------------------------------------------------------------------------------------------------------------
      # input :
      # un domaine sans http
      # output :
      #----------------------------------------------------------------------------------------------------------------
      #----------------------------------------------------------------------------------------------------------------


      def evaluate_as_saas(domain)
        try_count = 3


        begin
          parameters = Parameter.new(__FILE__)
          saas_host = parameters.saas_host.to_s
          saas_port = parameters.saas_port.to_s
          time_out = parameters.time_out_saas_evaluate.to_i
          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "domain"}) if domain.nil? or domain.empty?
          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "saas_host"}) if saas_host.nil? or saas_host.empty?
          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "saas_port"}) if saas_port.nil? or saas_port.empty?
          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "time_out_saas_evaluate"}) if time_out.nil? or time_out == 0


          #query http vers keywords saas
          href = URI.encode("http://#{saas_host}:#{saas_port}/?action=evaluate&keywords=#{@words}&domain=#{domain}&type=:link")

          @logger.an_event.debug "uri evaluate_saas : #{href}"

          keywords_io = open(href,
                             "r:utf-8",
                             {:read_timeout => time_out})

        rescue Exception => e
          sleep 5
          try_count -= 1
          retry if try_count > 0
          raise Error.new(KEYWORD_NOT_EVALUATED, :values => {:keyword => @words}, :error => e)

        else
          @engines = JSON.parse(keywords_io.string)

        end

      end


      def to_s
        s = "#{@words} "
        s += engines.to_s
        s
      end

      private
      def self.init_logging
        parameters = Parameter.new(__FILE__)
        @logger = Logging::Log.new(self, :staging => parameters.environment, :debugging => parameters.debugging)
        @logger
      end

    end

  end
end