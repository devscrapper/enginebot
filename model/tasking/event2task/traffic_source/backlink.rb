#encoding:utf-8
require 'net/http'
require 'nokogiri'
require 'addressable/uri'
require 'ruby-progressbar'
require 'thread'
require 'csv'
require 'open-uri'
require 'openssl'
require 'user_agent_randomizer'
require_relative '../../../../lib/parameter'
require_relative '../../../../lib/error'
#TODO supprimer ce quin'est pas nécessaire et deplacer dans /Traffic_source
module Tasking
  module TrafficSource


    class Backlink
      include Errors
      include Addressable
      ARGUMENT_NOT_DEFINE = 1600
      BAD_URL_BACKLINK = 1602
      BACKLINK_NOT_EVALUATED = 1603
      BACKLINK_NOT_SCRAPED = 1605

      @logger = nil

      SEPARATOR = ";"

      attr_reader :url,
                  :path,
                  :title,
                  :hostname,
                  :is_a_backlink

      #----------------------------------------------------------------------------------------------------------------
      # scrape(hostname, driver, opts)
      #----------------------------------------------------------------------------------------------------------------
      # fournit la liste des baclinks d'un domaine au moyen de majetic.com
      #----------------------------------------------------------------------------------------------------------------
      # input :
      # un domaine sans http
      # une instance de webdriver
      # un hash d'options : {:ip => @ip d proxy, :port => num port du proxy}, nil sinon
      # output :
      # StringIO contenant lesdonnÃ©es fournies par majestic
      #----------------------------------------------------------------------------------------------------------------
      #----------------------------------------------------------------------------------------------------------------

      def self.scrape_as_saas(hostname)
        init_logging
        #"www.epilation-laser-definitive.info"

        try_count = 3
        begin
          parameters = Parameter.new(__FILE__)
          saas_host = parameters.saas_host.to_s
          saas_port = parameters.saas_port.to_s
          time_out = parameters.time_out_saas_scrape.to_i

          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "hostname"}) if hostname.nil? or hostname.empty?
          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "time_out_saas_scrape"}) if time_out.nil? or time_out == 0

          #query http vers backlinks saas
          href = "http://#{saas_host}:#{saas_port}/?action=scrape&hostname=#{hostname}"
          @logger.an_event.debug "uri backlinks csv file majestic : #{href}"

          results = open(href,
                         "r:utf-8",
                         {:read_timeout => time_out})

        rescue Exception => e
          @logger.an_event.warn "scrape backlinks for #{hostname} : #{e.message}"
          sleep 5
          try_count -= 1
          retry if try_count > 0
          @logger.an_event.error "scrape backlinks for #{hostname} : #{e.message}"
          raise Error.new(BACKLINK_NOT_SCRAPED, :values => {:hostname => hostname}, :error => e)

        else
          @logger.an_event.info "scrape backlinks for #{hostname}"
          JSON.parse(results.read)

        end
      end

      def initialize(url)
        raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "url"}) if url.nil? or url.empty?

        begin
          @url = url.strip
          @title = ""
          @is_a_backlink = false
          uri = URI.parse(@url)

        rescue Exception => e
          raise Error.new(BAD_URL_BACKLINK, :values => {:url => "domain"}, :error => e)

        else
          @path = uri.path
          @hostname = uri.hostname

        end
        Backlink.init_logging
      end

      def to_s
        [@url, @is_a_backlink, @title].join(SEPARATOR)
      end

      def evaluate_as_saas(landing_url)
        try_count = 3

        begin
          parameters = Parameter.new(__FILE__)
          saas_host = parameters.saas_host.to_s
          saas_port = parameters.saas_port.to_s
          time_out = parameters.time_out_saas_evaluate.to_i

          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "time_out_saas_evaluate"}) if time_out.nil? or time_out == 0
          raise Error.new(ARGUMENT_NOT_DEFINE, :values => {:variable => "landing_url"}) if landing_url.nil? or landing_url.empty?

          #query http vers keywords saas
          href = URI.encode("http://#{saas_host}:#{saas_port}/?action=evaluate&backlink=#{@url}&landing_url=#{landing_url}")

          p "uri evaluate_saas : #{href}"

          is_backlink = open(href,
                             "r:utf-8",
                             {:read_timeout => time_out})


        rescue Exception => e
          sleep 5
          try_count -= 1
          retry if try_count > 0
          raise Error.new(BACKLINK_NOT_EVALUATED, :values => {:url => @url}, :error => e)

        else
          @is_a_backlink = JSON.parse(is_backlink.string)["is_a_backlink"]

        end


      end

      private
      def self.init_logging
              parameters = Parameter.new(__FILE__)
              @logger = Logging::Log.new(self, :staging => parameters.environment, :debugging => parameters.debugging)
            end

    end
  end
end