module Tasking
  PARAMETERS = File.dirname(__FILE__) + "/../../parameter/tasks_server.yml"
  ENVIRONMENT= File.dirname(__FILE__) + "/../../parameter/environment.yml"

  class Task


    attr :tasks_server_port,
         :cmd,
         :data,
         :logger


    def initialize(cmd, data)
      @cmd = cmd
      @data = data
      @tasks_server_port = 9151
      begin
        environment = YAML::load(File.open(ENVIRONMENT), "r:UTF-8")
        staging = environment["staging"] unless environment["staging"].nil?
      rescue Exception => e
        $stderr << "loading parameter file #{ENVIRONMENT} failed : #{e.message}" << "\n"
      end

      begin
        params = YAML::load(File.open(PARAMETERS), "r:UTF-8")
        @tasks_server_port = params[staging]["tasks_server_port"] unless params[staging]["tasks_server_port"].nil?
      rescue Exception => e
        $stderr << "loading parameters file #{PARAMETERS} failed : #{e.message}" << "\n"
      end

      @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)

    end

    def execute
      begin
        @logger.an_event.debug("message : #{{"cmd" => @cmd, "data" => @data}}")
        @logger.an_event.debug "@tasks_server_port #{@tasks_server_port}"
        Information.new({"cmd" => @cmd,
                         "data" => @data}).send_local(@tasks_server_port)

      rescue Exception => e
        raise StandardError, "ask execution task <#{@cmd}> to tasks server over => #{e}"
      else
        @logger.an_event.debug "ask execution task <#{@cmd}> to tasks server over"
      end
    end
  end
end