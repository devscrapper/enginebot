require_relative '../flow'
require 'rufus-scheduler'
require 'yaml'
require 'eventmachine'
require 'restclient'

module Scheduling
  class Scheduler
    OUTPUT = File.expand_path(File.join("..", "..", "..","output"), __FILE__)
    TMP = File.expand_path(File.join("..", "..", "..","tmp"), __FILE__)

    attr :os,
         :version,
         :pattern,
         :pool,
         :delay_periodic_scan,
         :logger


    def initialize(os, version, input_flow_servers, delay_periodic_scan, logger)
      @os = os
      @version = version
      @pattern = input_flow_servers[:pattern]
      @pool = EM::Pool.new
      @delay_periodic_scan = delay_periodic_scan


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
        if $staging == "development"
          start_date_time = Time.now + 30
          #decale la planification de 30s
        else
          start_date_time = Time.new(year.to_i, month.to_i, day.to_i, hour.to_i, min.to_i, sec.to_i)
        end

        if start_date_time > Time.now
          @logger.an_event.info "flow_visit #{flow_visit.basename} is plan at #{start_date_time}"

          change_state_visit_to_statupweb(flow_visit, :scheduled)

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
            visit_details = visit.read

            response = RestClient.post "http://#{ip}:#{port}/visits/new",
                                       visit_details,
                                       :content_type => :json,
                                       :accept => :json

            raise response.content if response.code != 200
            @logger.an_event.info "push visit flow #{visit.basename} to #{@os}/#{@version} input flow server #{ip}:#{port}"
          end
        end
      rescue Exception => e
        @logger.an_event.error "visit flow #{visit.basename} not push to #{@os}/#{@version} input flow server #{ip}:#{ip} : #{e.message}"
      else
        change_state_visit_to_statupweb(visit, :published)
        visit.archive

      end
    end

    def change_state_visit_to_statupweb(visit_flow, state)
      #informe statupweb de la creation d'une nouvelle visite
      # en cas d'erreur on ne leve as de'exception car c'est de la communication
      begin
        visit = YAML::load(visit_flow.read)

        response = RestClient.patch "http://#{$statupweb_server_ip}:#{$statupweb_server_port}/visits/#{visit[:visit][:id]}",
                                    JSON.generate({:state => state}),
                                    :content_type => :json,
                                    :accept => :json
        raise response.content if response.code != 201

      rescue Exception => e
        @logger.an_event.warn "cannot send scheduled state of visit #{visit[:visit][:id]} to statupweb (#{$statupweb_server_ip}:#{$statupweb_server_port}) => #{e.message}"
      else
      ensure
        visit_flow.close
      end
    end


  end

end