require_relative 'flow'
require 'pathname'
require 'rufus-scheduler'
require 'yaml'
require 'eventmachine'
require_relative 'communication'

class Scheduler
  OUTPUT = Pathname(File.join(File.dirname(__FILE__), '..', 'output')).realpath
  TMP = Pathname(File.join(File.dirname(__FILE__), '..', 'tmp')).realpath


  attr :os,
       :version,
       :pattern,
       :pool,
       :delay_periodic_scan,
       :logger,
       :authentification_server_port,
       :ftp_server_port


  def initialize(os, version, input_flow_servers, delay_periodic_scan, authentification_server_port, ftp_server_port, logger)
    @os = os
    @version = version
    @pattern = input_flow_servers[:pattern]
    @pool = EM::Pool.new
    @delay_periodic_scan = delay_periodic_scan
    @authentification_server_port = authentification_server_port
    @ftp_server_port = ftp_server_port
    @logger = logger
    @scheduler = Rufus::Scheduler.start_new


    input_flow_servers[:servers].each_value { |server|
      scheduler_instance = EM::ThreadedResource.new do
        {:ip => server[:ip], :port => server[:port]}
      end
      @pool.add scheduler_instance
      @logger.an_event.info "ressource #{@pattern} #{server[:ip]}:#{server[:port]} is on"
    }

    @logger.an_event.info "scheduler #{@pattern} is on"
  end


  def scan_visit_file
    begin
      EM::PeriodicTimer.new(@delay_periodic_scan) do
        @logger.an_event.info "scan visit file for #{@pattern} in #{TMP}"
        @logger.an_event.info "visit planed count for #{@pattern} #{@scheduler.jobs.size}"
        start_time = Time.now
        tmp_flow_visit_arr = Flow.list(TMP, {:type_flow => @pattern, :ext => "yml"})

        @logger.an_event.info "output flow count for #{@pattern} #{tmp_flow_visit_arr.size}"

        tmp_flow_visit_arr.each { |tmp_flow_visit|
          if tmp_flow_visit.exist?
            year, month, day, hour, min, sec = tmp_flow_visit.date.split(/-/)
            start_date_time =Time.new(year.to_i, month.to_i, day.to_i, hour.to_i, min.to_i, sec.to_i)

            if start_date_time > Time.now
              @logger.an_event.info "tmp_flow_visit #{tmp_flow_visit.basename} is plan at #{start_date_time}"
              tmp_flow_visit.move(OUTPUT)
              @scheduler.at start_date_time.to_s do
                send_visit_to_statupbot(tmp_flow_visit)
              end
            else
              @logger.an_event.warn "visit flow #{tmp_flow_visit.basename} not plan, too old"
            end
          else
            @logger.an_event.warn "visit flow #{tmp_flow_visit.basename} not exist"
          end
        }
      end
    rescue Exception => e
      @logger.an_event.error "scan visit file for #{@pattern} catch exception : #{e.message} => restarting"
      retry
    end
  end

  def send_visit_to_statupbot(visit)
    ip, port = nil, nil
    begin
      @pool.perform do |dispatcher|
        dispatcher.dispatch do |details|
          ip = details[:ip]
          port = details[:port]
          p ip
          p port
          @logger.an_event.info "visit file name #{visit.absolute_path}"
          visit.push(@authentification_server_port,
                     ip,
                     port,
                     @ftp_server_port,
                     visit.vol,
                     true)
        end
      end
    rescue Exception => e
      @logger.an_event.error "visit flow #{visit.basename} not push to #{@os}/#{@version} input flow server #{ip}:#{ip} : #{e.message}"
    else
      @logger.an_event.info "push visit flow #{visit.basename} to #{@os}/#{@version} input flow server #{ip}:#{port}"
    end
  end

end

