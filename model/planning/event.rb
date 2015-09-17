require 'rubygems'
require 'eventmachine'
require 'ice_cube'
require 'json'
require_relative '../communication'
require_relative '../../model/tasking/task'

module Planning
  class Event
    class EventException < StandardError
    end
    EXECUTE_ALL = "execute_all"
    EXECUTE_ONE = "execute_one"
    SAVE = "save"
    DELETE = "delete"

    include Tasking
    attr :key,
         :periodicity,
         :cmd,
         :business


    def initialize(key, cmd, periodicity=nil, business=nil)
      @key = key
      @cmd = cmd
      @periodicity = periodicity
      @business = business
    end

    def to_json(*a)
      {
          "key" => @key,
          "cmd" => @cmd,
          "periodicity" => @periodicity,
          "business" => @business
      }.to_json(*a)
    end

    def to_display

    end

    def to_s(*a)
      {
          "key" => @key,
          "cmd" => @cmd,
      }.to_s(*a)
    end

    def execute(toto)
      begin
        data = {
            "website_label" => @business["website_label"],
            "date_building" => @key["building_date"] || Date.today}.merge(@business)
        Task.new(@cmd, data).execute
      rescue Exception => e
        raise EventException, "cannot execute event <#{@cmd}> for <#{@business["website_label"]}> because #{e}"
      end
    end
  end


end