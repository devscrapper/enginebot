require_relative 'flow'
require 'rufus-scheduler'
require 'yaml'
require 'eventmachine'


class Scheduler
  OUTPUT = File.expand_path(File.join("..", "..", "output"), __FILE__)
  TMP = File.expand_path(File.join("..", "..", "tmp"), __FILE__)

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


    # quand un scheduler a été stoppé(deploiement nouvelle version), les visites planifiées ne le sont plus.
    # les visites planfifiées ont été stockées dnas output.
    # pour éviter de perdre des visites lors du re demarrage du scheduler 
    # on planifie une nouvelle fois ces visites lors de la creation du scheduler par scan du repertoire OUTPUT
    # on ne planifie que les visites dont la date de demarrage est dans le futur de 5 * 60s
    @logger.an_event.info "scan visit file for #{@pattern} in #{OUTPUT}"

    output_flow_visit_arr = Flow.list(OUTPUT, {:type_flow => @pattern, :ext => "yml"})
    @logger.an_event.info "output flow count for #{@pattern} #{output_flow_visit_arr.size}"

    output_flow_visit_arr.each { |output_flow_visit|
      plan_visit_file(output_flow_visit)
    }

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
        tmp_flow_visit_arr = Flow.list(TMP, {:type_flow => @pattern, :ext => "yml"})

        tmp_flow_visit_arr.each { |tmp_flow_visit|
          plan_visit_file(tmp_flow_visit)
          tmp_flow_visit.move(OUTPUT)
        }
      end
      EM::PeriodicTimer.new(5 * 60) do
        @logger.an_event.info "visit planed count for #{@pattern} #{@scheduler.jobs.size}"
      end
    rescue Exception => e
      @logger.an_event.error "scan visit file for #{@pattern} catch exception : #{e.message} => restarting"
      retry
    end
  end


  def plan_visit_file(flow_visit)
    if flow_visit.exist?
      year, month, day, hour, min, sec = flow_visit.date.split(/-/)
      start_date_time = Time.new(year.to_i, month.to_i, day.to_i, hour.to_i, min.to_i, sec.to_i)

      if start_date_time > Time.now
        @logger.an_event.info "flow_visit #{flow_visit.basename} is plan at #{start_date_time}"

        @scheduler.at start_date_time.to_s do
          send_visit_to_statupbot(flow_visit)
        end

      else
        @logger.an_event.warn "visit flow #{flow_visit.basename} not plan, too old"
        flow_visit.archive
      end
    else
      @logger.an_event.warn "visit flow #{flow_visit.basename} not exist"
    end
  end

  def send_visit_to_statupbot(visit)
    ip, port = nil, nil
    begin
      @pool.perform do |dispatcher|
        dispatcher.dispatch do |details|
          ip = details[:ip]
          port = details[:port]
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
      #pas besoin d'archiver les flow car ils automatiquement supprimés lors du download vers le statupbot
    end
  end

end

