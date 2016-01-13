require_relative '../communication'
module Tasking
  PARAMETERS = "tasks_server.rb"


  class Task


    attr :tasks_server_port,
         :cmd,
         :data,
         :logger


    def initialize(cmd, data)
      @cmd = cmd
      @data = data
      @tasks_server_port = 9151
      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
      begin
        parameters = Parameter.new(PARAMETERS)

      rescue Exception => e
        $stderr << e.message << "\n"

      else
        @tasks_server_port = parameters.listening_port #TODO remplacer par une variable passée à la Connectiontask qui la passera à l'object Task dont héritera toutes les actions
        if @tasks_server_port.nil?
          @logger.an_event.error "@tasks_server_port parameters not define"
        end
      end

    end

    def execute
      begin
        @logger.an_event.debug("message : #{{"cmd" => @cmd, "data" => @data}}")
        @logger.an_event.debug "@tasks_server_port #{@tasks_server_port}"
        Information.new({"cmd" => @cmd,
                         "data" => @data}).send_local(@tasks_server_port)

      rescue Exception => e
        raise StandardError, "ask execution task <#{@cmd}> to tasks server over => #{e.message}"

      else
        @logger.an_event.debug "ask execution task <#{@cmd}> to tasks server"

      end
    end
  end
end