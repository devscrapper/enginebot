require 'rubygems' # if you use RubyGems
require 'eventmachine'
require_relative 'task_list'
#TODO à supprimer
module Tasking
  class TaskConnection < EventMachine::Connection
    attr :logger


    def initialize(logger)
      @logger = logger
    end

    def receive_data param
      @logger.an_event.debug "data receive <#{param}>"
      close_connection

      begin
        data = YAML::load param
        context = []
        cmd = data["cmd"]
        data_cmd = data["data"]
        context = [cmd]

        @logger.ndc context
        @logger.an_event.debug "cmd <#{cmd}>"
        @logger.an_event.debug "data cmd <#{data_cmd}>"
        @logger.an_event.debug "context <#{context}>"
        Tasklist.new(data_cmd).method(cmd).call()
      rescue Exception => e
        @logger.an_event.fatal "tasks_server not execute task <#{cmd}> : #{e}"

      end

    end


  end
end