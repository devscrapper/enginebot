# encoding: UTF-8

require_relative '../../lib/error'
require_relative 'event2task/objective/objectives'
require_relative 'event2task/visit/visits'
require_relative 'event2task/statistic/statistic'
require_relative 'event2task/statistic/chosens'
require_relative 'event2task/statistic/default'
require_relative 'event2task/statistic/custom'
#require_relative 'event2task/statistic/google_analytics' #TODO ko with ruby 223
require_relative 'event2task/traffic_source/chosens'
require_relative 'event2task/traffic_source/default'
require_relative 'event2task/traffic_source/organic'
require_relative 'event2task/traffic_source/referral'
require_relative 'event2task/traffic_source/direct'
require_relative '../planning/event'
require 'rest-client'
require 'json'
# TODO a supprimer qd toutes les tasks auront été refondus
module Tasking
  class Tasklist
    include Errors


    ACTION_NOT_EXECUTE = 1802
    attr :data, :logger

    def initialize(data)
      @data = data
      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
    end

    #--------------------------------------------------------------------------------------
    # STATISTIC
    #--------------------------------------------------------------------------------------
    def Scraping_device_platform_resolution

      execute(__method__) {
        case @data[:statistic_type].to_sym
          when :ga
            Statistic::Googleanalytics.new.device_platform_resolution(@data[:website_label], @data[:building_date], @data[:profil_id_ga], @data[:website_id])

          when :default, :custom
            Statistic::Default.new(@data[:website_label], @data[:building_date], @data[:policy_type]).device_platform_resolution

        end
      }
    end

    def Scraping_device_platform_plugin

      execute(__method__) {
        case @data[:statistic_type].to_sym
          when :ga
            Statistic::Googleanalytics.new.device_platform_plugin(@data[:website_label], @data[:building_date], @data[:profil_id_ga], @data[:website_id])

          when :default, :custom
            Statistic::Default.new(@data[:website_label], @data[:building_date], @data[:policy_type]).device_platform_plugin

        end
      }

    end

    def Scraping_behaviour

      execute(__method__) {
        case @data[:statistic_type].to_sym
          when :ga
            Statistic::Googleanalytics.new.behaviour(@data[:website_label], @data[:building_date], @data[:profil_id_ga], @data[:website_id]) #TODO � corriger comme default ko with ruby 223

          when :default
            Statistic::Default.new(@data[:website_label], @data[:building_date], @data[:policy_type]).behaviour

          when :custom
            Statistic::Custom.new(@data[:website_label],
                                  @data[:building_date],
                                  @data[:policy_type]).behaviour(@data[:percent_new_visit],
                                                                 @data[:visit_bounce_rate],
                                                                 @data[:avg_time_on_site],
                                                                 @data[:page_views_per_visit],
                                                                 @data[:count_visits_per_day])
        end
      }
    end

    def Scraping_hourly_daily_distribution

      execute(__method__) {
        case @data[:statistic_type].to_sym
          when :ga
            Statistic::Googleanalytics.new.hourly_daily_distribution(@data[:website_label], @data[:building_date], @data[:profil_id_ga], @data[:website_id]) #TODO � corriger comme default   ko with ruby 223

          when :default
            Statistic::Default.new(@data[:website_label], @data[:building_date], @data[:policy_type]).hourly_daily_distribution

          when :custom
            Statistic::Custom.new(@data[:website_label], @data[:building_date], @data[:policy_type]).hourly_daily_distribution(@data[:hourly_daily_distribution])

        end
      }
    end

    def Building_device_platform
      execute(__method__) {
        Statistic::Statistic.new(@data[:website_label],
                                 @data[:building_date],
                                 @data[:policy_type]).Building_device_platform
      }
    end

    def Building_hourly_daily_distribution
      execute(__method__) {
        Statistic::Statistic.new(@data[:website_label],
                                 @data[:building_date],
                                 @data[:policy_type]).Building_hourly_daily_distribution
      }
    end

    def Building_behaviour
      execute(__method__) {
        Statistic::Statistic.new(@data[:website_label],
                                 @data[:building_date],
                                 @data[:policy_type]).Building_behaviour
      }
    end

    def Choosing_device_platform
      execute(__method__) {
        Statistic::Chosens.new(@data[:website_label],
                               @data[:building_date],
                               @data[:policy_type]).Choosing_device_platform(is_nil_or_empty? { @data[:count_visits] }.to_i) }
    end

    #--------------------------------------------------------------------------------------
    # TRAFFIC SOURCE
    #--------------------------------------------------------------------------------------
    def Building_landing_pages_direct
      execute(__method__) {
        TrafficSource::TrafficSource.new(@data[:website_label],
                                         @data[:building_date],
                                         @data[:policy_type]).Building_landing_pages(:direct)
      }
    end

    def Building_landing_pages_organic
      execute(__method__) {
        TrafficSource::TrafficSource.new(@data[:website_label],
                                         @data[:building_date],
                                         @data[:policy_type]).Building_landing_pages(:organic)
      }
    end

    def Building_landing_pages_referral
      execute(__method__) {
        TrafficSource::TrafficSource.new(@data[:website_label],
                                         @data[:building_date],
                                         @data[:policy_type]).Building_landing_pages(:referral)
      }
    end

    def Choosing_landing_pages
      execute(__method__) {
        TrafficSource::Chosens.new(@data[:website_label],
                                   @data[:building_date],
                                   @data[:policy_type]).Choosing_landing_pages(is_nil_or_empty? { @data[:direct_medium_percent] }.to_i,
                                                                               is_nil_or_empty? { @data[:organic_medium_percent] }.to_i,
                                                                               is_nil_or_empty? { @data[:referral_medium_percent] }.to_i,
                                                                               is_nil_or_empty? { @data[:count_visits] }.to_i) }
    end


    def Scraping_traffic_source_organic

      execute(__method__) {
        case @data[:policy_type].to_sym
          when :traffic
            TrafficSource::Organic.new(@data[:website_label],
                                       @data[:building_date],
                                       @data[:policy_type]).make_repository(@data[:url_root], # 10mn de suggesting
                                                                            $staging == "development" ? 10 /(24 * 60) : @data[:max_duration])
          when :rank
            #Si il y a de smot cl� param�trer dans la tache alors elle est issue dune policy Rank
            TrafficSource::Default.new(@data[:website_label], @data[:building_date], @data[:policy_type]).make_repository(@data[:keywords])
        end
      }

    end

    def Scraping_traffic_source_referral

      execute(__method__) {
        TrafficSource::Referral.new(@data[:website_label],
                                    @data[:building_date],
                                    @data[:policy_type]).make_repository(@data[:url_root], #en dev 5 backlink max, zero = all
                                                                         $staging == "development" ? 5 : 0)
      }
    end

    def Scraping_website

      execute(__method__) { |event_id|
        $stderr << @data[:policy_id] << '\n'
        TrafficSource::Direct.new(@data[:website_label],
                                  @data[:building_date],
                                  @data[:policy_type],
                                  event_id,
                                  @data[:policy_id]).scraping_pages(@data[:url_root],
                                                                    $staging == "development" ? 10 : @data[:count_page],
                                                                    @data[:max_duration],
                                                                    @data[:schemes],
                                                                    @data[:types])
      }
    end

    def Evaluating_traffic_source_referral

      execute(__method__) {
        TrafficSource::Referral.new(@data[:website_label],
                                    @data[:building_date],
                                    @data[:policy_type]).evaluate(@data[:count_max]) }
    end

    def Evaluating_traffic_source_organic

      execute(__method__) {
        # l'evaluation est identique pour Organic & Default
        TrafficSource::Organic.new(@data[:website_label],
                                   @data[:building_date],
                                   @data[:policy_type]).evaluate(@data[:count_max], @data[:url_root])
      }
    end

    #--------------------------------------------------------------------------------------
    # OBJECTIVE
    #--------------------------------------------------------------------------------------
    def Building_objectives

      execute(__method__) {
        case @data[:policy_type]
          when "traffic"
            Objective::Objectives.new(@data[:website_label],
                                      @data[:building_date],
                                      @data[:policy_id],
                                      @data[:website_id],
                                      @data[:policy_type],
                                      @data[:count_weeks]).Building_objectives_traffic(is_nil_or_empty? { @data[:change_count_visits_percent] }.to_i,
                                                                                       is_nil_or_empty? { @data[:change_bounce_visits_percent] }.to_i,
                                                                                       is_nil_or_empty? { @data[:direct_medium_percent] }.to_i,
                                                                                       is_nil_or_empty? { @data[:organic_medium_percent] }.to_i,
                                                                                       is_nil_or_empty? { @data[:referral_medium_percent] }.to_i,
                                                                                       is_nil_or_empty? { @data[:advertising_percent] }.to_i,
                                                                                       is_nil_or_empty? { @data[:advertisers] },
                                                                                       is_nil_or_empty? { @data[:monday_start] },
                                                                                       is_nil_or_empty? { @data[:url_root] },
                                                                                       is_nil_or_empty? { @data[:min_count_page_advertiser] },
                                                                                       is_nil_or_empty? { @data[:max_count_page_advertiser] },
                                                                                       is_nil_or_empty? { @data[:min_duration_page_advertiser] },
                                                                                       is_nil_or_empty? { @data[:max_duration_page_advertiser] },
                                                                                       is_nil_or_empty? { @data[:percent_local_page_advertiser] },
                                                                                       is_nil_or_empty? { @data[:duration_referral] },
                                                                                       is_nil_or_empty? { @data[:min_count_page_organic] },
                                                                                       is_nil_or_empty? { @data[:max_count_page_organic] },
                                                                                       is_nil_or_empty? { @data[:min_duration_page_organic] },
                                                                                       is_nil_or_empty? { @data[:max_duration_page_organic] },
                                                                                       is_nil_or_empty? { @data[:min_duration] },
                                                                                       is_nil_or_empty? { @data[:max_duration] },
                                                                                       is_nil_or_empty? { @data[:min_duration_website] },
                                                                                       is_nil_or_empty? { @data[:min_pages_website] })
          when "rank"
            Objective::Objectives.new(@data[:website_label],
                                      @data[:building_date],
                                      @data[:policy_id],
                                      @data[:website_id],
                                      @data[:policy_type],
                                      @data[:count_weeks]).Building_objectives_rank(is_nil_or_empty? { @data[:count_visits_per_day] }.to_i,
                                                                                    is_nil_or_empty? { @data[:monday_start] },
                                                                                    is_nil_or_empty? { @data[:url_root] },
                                                                                    is_nil_or_empty? { @data[:min_count_page_advertiser] },
                                                                                    is_nil_or_empty? { @data[:max_count_page_advertiser] },
                                                                                    is_nil_or_empty? { @data[:min_duration_page_advertiser] },
                                                                                    is_nil_or_empty? { @data[:max_duration_page_advertiser] },
                                                                                    is_nil_or_empty? { @data[:percent_local_page_advertiser] },
                                                                                    is_nil_or_empty? { @data[:duration_referral] },
                                                                                    is_nil_or_empty? { @data[:min_count_page_organic] },
                                                                                    is_nil_or_empty? { @data[:max_count_page_organic] },
                                                                                    is_nil_or_empty? { @data[:min_duration_page_organic] },
                                                                                    is_nil_or_empty? { @data[:max_duration_page_organic] },
                                                                                    is_nil_or_empty? { @data[:min_duration] },
                                                                                    is_nil_or_empty? { @data[:max_duration] },
                                                                                    is_nil_or_empty? { @data[:min_duration_website] },
                                                                                    is_nil_or_empty? { @data[:min_pages_website] })
        end
      }


    end

    #--------------------------------------------------------------------------------------
    # VISIT
    #--------------------------------------------------------------------------------------

    def Building_visits
      execute(__method__) {
        Visit::Visits.new(@data[:website_label],
                          @data[:building_date],
                          @data[:policy_type],
                          @data[:website_id],
                          @data[:policy_id]).Building_visits(is_nil_or_empty? { @data[:count_visits] }.to_i,
                                                             is_nil_or_empty? { @data[:visit_bounce_rate] }.to_f,
                                                             is_nil_or_empty? { @data[:page_views_per_visit] }.to_f,
                                                             is_nil_or_empty? { @data[:avg_time_on_site] }.to_f,
                                                             is_nil_or_empty? { @data[:min_durations] }.to_i,
                                                             is_nil_or_empty? { @data[:min_pages] }.to_i) }
    end

    def Building_planification
      execute(__method__) {
        Visit::Visits.new(@data[:website_label],
                          @data[:building_date],
                          @data[:policy_type],
                          @data[:website_id],
                          @data[:policy_id]).Building_planification(is_nil_or_empty? { @data[:hourly_distribution] },
                                                                    is_nil_or_empty? { @data[:count_visits] }.to_i) }
    end

    def Extending_visits
      execute(__method__) {

        Visit::Visits.new(@data[:website_label],
                          @data[:building_date],
                          @data[:policy_type],
                          @data[:website_id],
                          @data[:policy_id]).Extending_visits(is_nil_or_empty? { @data[:count_visits] }.to_i,
                                                              is_nil_or_empty? { @data[:advertising_percent].to_i },
                                                              is_nil_or_empty? { @data[:advertisers] }) }
    end

    def Reporting_visits
      execute(__method__) {
        Visit::Visits.new(@data[:website_label],
                          @data[:building_date],
                          @data[:policy_type],
                          @data[:website_id], @data[:policy_id]).Reporting_visits }
    end

    def Publishing_visits
      execute(__method__) {
        Visit::Visits.new(@data[:website_label],
                          @data[:building_date],
                          @data[:policy_type],
                          @data[:website_id],
                          @data[:policy_id]).Publishing_visits_by_hour(@data[:min_count_page_advertiser].to_i,
                                                                       @data[:max_count_page_advertiser].to_i,
                                                                       @data[:min_duration_page_advertiser].to_i,
                                                                       @data[:max_duration_page_advertiser].to_i,
                                                                       @data[:percent_local_page_advertiser].to_i,
                                                                       @data[:duration_referral].to_i,
                                                                       @data[:min_count_page_organic].to_i,
                                                                       @data[:max_count_page_organic].to_i,
                                                                       @data[:min_duration_page_orgcaanic].to_i,
                                                                       @data[:max_duration_page_organic].to_i,
                                                                       @data[:min_duration].to_i,
                                                                       @data[:max_duration].to_i)
      }
    end


    #--------------------------------------------------------------------------------------
    # private
    #--------------------------------------------------------------------------------------

    private


    def execute(task, &block)
      info = ["policy (type/id) : #{@data[:policy_type]} / #{@data[:policy_id]}",
              " website (label/id) : #{@data[:website_label]} / #{@data[:website_id]}",
              " date : #{@data[:building_date]}"]
      info << " objective_id : #{@data[:objective_id]}" unless @data[:objective_id].nil?

      action = proc {
        begin
          # perform a long-running operation here, such as a database query.
          send_state_to_calendar(@data[:event_id], Planning::Event::START, info)
          @logger.an_event.info "task <#{task}> for <#{info.join(",")}> is start"
          send_task_to_statupweb(@data[:policy_id], @data[:policy_type], task, Planning::Event::START, info)

          yield (@data[:event_id])

        rescue Error => e
          results = e

        rescue Exception => e
          @logger.an_event.error "task <#{task}> for <#{info.join(",")}> is over => #{e.message}"
          results = Error.new(ACTION_NOT_EXECUTE, :values => {:action => task}, :error => e)

        else
          @logger.an_event.info "task <#{task}> for <#{info.join(",")}> is over"
          results # as usual, the last expression evaluated in the block will be the return value.

        ensure

        end
      }
      callback = proc { |results|
        # do something with result here, such as send it back to a network client.

        if results.is_a?(Error)
          send_state_to_calendar(@data[:event_id], Planning::Event::FAIL, info)
          send_task_to_statupweb(@data[:policy_id], @data[:policy_type], task, Planning::Event::FAIL, info)

        else
          # scraping website utilise spawn => tout en asycnhrone => il enverra l'Event::over à calendar
          # il n'enverra jamais Event::Fail à calendar.
          if task != :Scraping_website
            send_state_to_calendar(@data[:event_id], Planning::Event::OVER, info)
            send_task_to_statupweb(@data[:policy_id], @data[:policy_type], task, Planning::Event::OVER, info)
          end

        end

      }

      if $staging == "development" #en dev tout ext exécuté hors thread pour pouvoir debugger
        begin
          results = action.call

        rescue Exception => e
          @logger.an_event.error e.message
          callback.call(e)

        else
          callback.call(results)

        end
      else # en test & production tout est executé dans un thread
        EM.defer(action, callback)
      end

    end

    private


    def send_state_to_calendar(event_id, state, info)
      # informe le calendar du nouvelle etat de la tache (start/over/fail).

      begin

        response = RestClient.patch "http://localhost:#{$calendar_server_port}/tasks/#{event_id}/?state=#{state}", :content_type => :json, :accept => :json

        raise response.content if response.code != 200

      rescue Exception => e
        raise StandardError, "task <#{info.join(",")}> not update state : #{state} => #{e.message}"
      else

      end
    end

    def send_task_to_statupweb(policy_id, policy_type, label, state, info)
      # informe statupweb du nouvel etat d'un task
      # en cas d'erreur on ne leve pas une exception car cela ne met en peril le comportement fonctionnel de derouelement de lexecution de la policy.
      # on peut identifier avec event_id la task déjà pésente dans statupweb pour faire un update plutot que d'jouter une nouvelle task
      # avoir si le besoin se fait sentir en terme de présention IHM (plus lisible)
      begin
        task = {:policy_id => policy_id,
                :policy_type => policy_type,
                :label => label,
                :state => state,
                :time => Time.now
        }
        response = RestClient.post "http://#{$statupweb_server_ip}:#{$statupweb_server_port}/tasks/",
                                   JSON.generate(task),
                                   :content_type => :json,
                                   :accept => :json
        raise response.content if response.code != 201

      rescue Exception => e
        @logger.an_event.warn "task <#{info.join(",")}> not update state : #{state} to statupweb #{$statupweb_server_ip}:#{$statupweb_server_port}=> #{e.message}"
      else

      end
    end

    def is_nil_or_empty?
      @logger.an_event.debug yield
      raise StandardError, "argument is undefine" if yield.nil?
      raise StandardError, "argument is empty" if !yield.nil? and yield.is_a?(String) and yield.empty?
      yield
    end
  end
end
