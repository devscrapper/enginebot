require 'rubygems'
require 'eventmachine'
require 'ice_cube'
require 'json'
require 'uuid'
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
    attr :id,
         :key,
         :periodicity,
         :cmd,
         :business

    attr_accessor :pre_tasks_over,
                  :pre_tasks_running,
                  :state,
                  :pre_tasks


    def initialize(key, cmd, options={}, id=nil)
      @id = UUID.generate(:compact) if id.nil?
      @id = id unless id.nil?
      @key = key.merge({"task" => cmd})
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
          "id" => @id,
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
          "id" => @id,
          "key" => @key
      }.to_s(*a)
    end

    def to_html
      # {"key":{"policy_id":3},
      #     "cmd":"Scraping_device_platform_plugin",
      #     "state":"over",
      #     "pre_tasks_over":[],
      #     "pre_tasks_running":[],
      #     "pre_tasks":[],
      #     "periodicity":"---\n:start_date: 2016-01-02 01:30:00.000000000 +01:00\n:end_time: 2016-02-01 00:00:00.000000000 +01:00\n:rrules:\n- :validations: {}\n  :rule_type: IceCube::WeeklyRule\n  :interval: 1\n  :week_start: 0\n  :until: 2016-02-01 00:00:00.000000000 +01:00\n:exrules: []\n:rtimes: []\n:extimes: []\n",
      #     "business":{"policy_type":"traffic","policy_id":3,"website_label":"epilation-laser-definitive-default","website_id":1,"statistic_type":"default"}},

      <<-_end_of_html_
      <ul>
          <li><b>id</b> : #{@id}</li>
          <li><b>key</b> : #{@key}</li>
          <li><b>cmd</b> : #{@cmd}</li>
          <li><b>state</b> : #{@state}</li>
          <li><b>pre_tasks</b> : #{@pre_tasks}</li>
          <li><b>pre_tasks_running</b> : #{@pre_tasks_running}</li>
          <li><b>pre_tasks_over</b> : #{@pre_tasks_over}</li>
          <li><b>periodicity</b> : #{@periodicity}</li>
          <li><b>business</b> : #{@business}</li>
          <li><a href="/tasks/execute/?id=#{@id}">Execute</a></li>
       </ul>
      _end_of_html_

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