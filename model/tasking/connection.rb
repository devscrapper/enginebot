require 'rubygems' # if you use RubyGems
require 'eventmachine'
require_relative 'task_list'
require_relative '../planning/event'

class Toto
  attr_reader :pre, :val

  def initialize(val, pre=[])
    @val = val
    @pre = pre
  end


  def self.tri(arr)


    begin
      i =0
      change = 0
      while i < arr.size-1
        j = i + 1
        while j < arr.size
          if arr[i].pre.include?(arr[j].val) or arr[j].pre.empty?
            tmp = arr[i]
            arr[i] = arr[j]
            arr[j] = tmp
            change +=1
          end
          j+=1
        end
        i +=1
      end
      p arr
    end while change > 0
    arr
  end
end

module Tasking

  module TaskConnection
    attr :logger

    include EM::P::ObjectProtocol

    def initialize(logger)
      @logger = logger
    end


    def receive_object event
      @logger.an_event.debug "data receive <#{event}>"
      close_connection

      begin
        task = eval(event.task_label.capitalize).new(event).execute
      rescue Exception => e
        @logger.an_event.warn "event #{event.label} not manage with new task system : #{e.message}, use old one"

       begin
          context = []
          cmd = event.label
          data_cmd = {
              :event_id => event.id,
              :website_label => event.website_label,
              :building_date => (event.building_date.empty? or event.building_date.nil?) ? Date.today : event.building_date
          }
          data_cmd.merge!(event.business)

          @logger.an_event.debug "cmd <#{cmd}>"
          @logger.an_event.debug "data cmd <#{data_cmd}>"
          @logger.an_event.debug "context <#{context}>"
          Tasklist.new(data_cmd).method(cmd).call()
        rescue Exception => e
          @logger.an_event.error "cannot execute cmd <#{cmd}> : #{e.message}"
        else

       end

      end
    end


  end
end