require 'rubygems'
require 'eventmachine'
require 'ice_cube'
require 'json'
require_relative '../communication'
require_relative 'task'

module Planning
  class Event
    class EventException < StandardError
    end
    EXECUTE_ALL = "execute_all"
    EXECUTE_ONE = "execute_one"
    SAVE = "save"
    DELETE = "delete"
    #states
    OVER = "over"
    START = "start"
    INIT = 'init'

    include Tasking
    attr :key,
         :periodicity,
         :cmd,
         :business

    attr_accessor :pre_tasks_over,
                  :pre_tasks_running,
                  :state,
                  :pre_tasks


    def initialize(key, cmd, options={})
      @key = key
      @cmd = cmd
      @state = options.fetch("state", INIT)
      @pre_tasks_over = options.fetch("pre_tasks_over", [])
      @pre_tasks_running = options.fetch("pre_tasks_running", [])
      @pre_tasks = options.fetch("pre_tasks", [])
      @periodicity = options.fetch("periodicity", "")
      @business = options.fetch("business", {})
    end

    def to_json(*a)
      {
          "key" => @key,
          "cmd" => @cmd,
          "state" => @state,
          "pre_tasks_over" => @pre_tasks_over,
          "pre_tasks_running" => @pre_tasks_running,
          "pre_tasks" => @pre_tasks,
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

    def execute
      begin
        data = {
            'website_label' => @business['website_label'],
            "date_building" => @key["building_date"] || Date.today}.merge(@business)
        Task.new(@cmd, data).execute
      rescue Exception => e
        raise EventException, "cannot execute event <#{@cmd}> for <#{@business["website_label"]}> because #{e}"
      end
    end
  end


end