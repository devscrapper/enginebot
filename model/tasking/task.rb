# encoding: UTF-8
require_relative '../../lib/error'
require_relative '../../lib/logging'
require_relative '../planning/event'

module Tasking
  class Task
    include Errors


    ACTION_NOT_EXECUTE = 1802

    attr :logger,
         :label, # String, nom de la task
         :event_id, # identifiant de la event pour maj le calendar
         :website_label, #labe di site pour lequel on bosse, intervient dans le libelle des flow
         :policy_type, #type de policy géree : Traffic, Rank, intervient dans le libelle des flow
         :building_date #date d'exécution de la tache qui intervient dans le libelle des flow
    # les données business specificque à chaque task sotn déclarées dans la tache elle meme
    # qui héritera de Task

    attr_reader # données accessible en lecture seule pour le moement pas d'idée


    def initialize(event, logger=nil)
      @label = event.task_label
      @event_id = event.id
      @website_label = event.website_label
      @policy_type = event.policy_type
      @building_date = (event.building_date.empty? or event.building_date.nil?) ? Date.today : event.building_date
      @logger = logger || Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
    end


    def execute(&block)

      action = proc {
        begin
          # perform a long-running operation here, such as a database query.
          send_state_to_calendar(Planning::Event::START)
          @logger.an_event.info "#{self} is start"
          yield

        rescue Error => e
          results = e

        rescue Exception => e
          results = Error.new(ACTION_NOT_EXECUTE, :values => {:action => self.to_s}, :error => e)

        else
          @logger.an_event.info "#{self} is over"
          results # as usual, the last expression evaluated in the block will be the return value.

        ensure

        end
      }
      callback = proc { |results|
        # do something with result here, such as send it back to a network client.

        if results.is_a?(Error)
          send_state_to_calendar(Planning::Event::FAIL)

        else
          # scraping website utilise spawn => tout en asycnhrone => il enverra l'Event::over à calendar
          # il n'enverra jamais Event::Fail à calendar.
          send_state_to_calendar( Planning::Event::OVER) if task != :Scraping_website  # TODO à déplacer dans la Task Scraing_website

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

    def to_s(*a)
      ["task : #{@label}",
       "policy : #{@policy_type}}",
       " website #{@website_label}}",
       " date : #{@building_date}"].join(",").to_s(*a)
    end

    private


    def send_state_to_calendar(state)
      # informe le calendar du nouvelle etat de la tache (start/over/fail).

      begin

        response = RestClient.patch "http://localhost:#{$calendar_server_port}/tasks/#{@event_id}/?state=#{state}", :content_type => :json, :accept => :json

        raise response.content if response.code != 200

      rescue Exception => e
        @logger.an_event.error "#{self} not update state : #{state} : #{e.message}"

      else

      end
    end
  end
end