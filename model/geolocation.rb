class Geolocation
  OUTPUT = Pathname(File.join(File.dirname(__FILE__), '..', 'output')).realpath
  TMP = Pathname(File.join(File.dirname(__FILE__), '..', 'tmp')).realpath


  # les proxy sont stockés dans un fichier geolocations_#{staging} par staging : alimentation pour le moment manuelle
  # les proxy sont publiés dans OUTPUT toutes les heures avec autant d'occurence de fichier que serveur input_flow qui réceptionne le fichier
  # autrement dit il est autant d'occurence de geolocations_#{staging}_today_hour.txt que d'instance d'os/version en ligne décrite dans le
  # fichier de paramètage du serveur scheduler_server.
  def self.send(inputflow_factories, authentification_server_port, ftp_server_port, logger)
    inputflow_factories.each { |os_label, version|
      version.each { |version_label, input_flow_servers|
        input_flow_servers[:servers].each_value { |input_flow_server|
          begin
            geo_file_source = "geolocations_#{$staging}.txt"
            geolocations_flow = Flow.from_basename(OUTPUT, "geolocations_#{$staging}_#{Date.today.strftime("%Y-%m-%d")}_#{Time.now.hour}.txt")

            raise "flow <#{geo_file_source}> not exist" unless File.exist?(File.join(TMP, geo_file_source))

            FileUtils.cp(File.join(TMP, geo_file_source), geolocations_flow.absolute_path)

            geolocations_flow.push(authentification_server_port,
                                   input_flow_server[:ip],
                                   input_flow_server[:port],
                                   ftp_server_port,
                                   geolocations_flow.vol,
                                   true)

          rescue Exception => e
            logger.a_log.error "geolocations flow <#{geolocations_flow.basename}> not push to input flow server #{input_flow_server[:ip]}:#{input_flow_server[:port]} : #{e.message}"
          else
            logger.a_log.info "geolocations flow <#{geolocations_flow.basename}> push to input flow server #{input_flow_server[:ip]}:#{input_flow_server[:port]}"
          end
        }
      }
    }

  end
end