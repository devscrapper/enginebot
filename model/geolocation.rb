class Geolocation
  OUTPUT = Pathname(File.join(File.dirname(__FILE__), '..', 'output')).realpath
  TMP = Pathname(File.join(File.dirname(__FILE__), '..', 'tmp')).realpath


  def self.send(inputflow_factories, authentification_server_port, ftp_server_port, logger)
    inputflow_factories.each { |os_label, version|
      version.each { |version_label, input_flow_servers|
        input_flow_servers[:servers].each_value { |input_flow_server|
          begin
            geolocations_flow = Flow.from_basename(OUTPUT, "geolocations_#{$staging}_#{Date.today.strftime("%Y-%m-%d")}_#{Time.now.hour}.txt")

            FileUtils.cp(File.join(TMP, "geolocations_#{$staging}.txt"), geolocations_flow.absolute_path)

            geolocations_flow.push(authentification_server_port,
                                   input_flow_server[:ip],
                                   input_flow_server[:port],
                                   ftp_server_port,
                                   geolocations_flow.vol,
                                   true)

          rescue Exception => e
            logger.a_log.error "geolocations flow not push to input flow server #{input_flow_server[:ip]}:#{input_flow_server[:port]} : #{e.message}"
          else
            logger.a_log.info "geolocations flow push to input flow server #{input_flow_server[:ip]}:#{input_flow_server[:port]}"
          end
        }
      }
    }

  end
end