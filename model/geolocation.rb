class Geolocation
  OUTPUT = Pathname(File.join(File.dirname(__FILE__), '..', 'output')).realpath
  TMP = Pathname(File.join(File.dirname(__FILE__), '..', 'tmp')).realpath


  # les proxy sont stockés dans un fichier TMP/geolocations_#{staging} par staging : alimentation pour le moment manuelle
  # les proxy sont publiés dans OUTPUT toutes les heures avec autant d'occurence de fichier que serveur input_flow qui réceptionne le fichier
  # autrement dit il est autant d'occurence de geolocations_#{staging}_today_hour.txt que d'instance d'os/version en ligne décrite dans le
  # fichier de paramètage du serveur scheduler_server.
  # contenu du fichier doit être :
  # code pays sur 2 car; scheme du proxy ; domaine duproxy ; port du proxy ; user du proxy ; mot de passe du proxy
  # fr;http;muz11-wbsswsg.ca-technologies.fr;8080;et00752;Bremb@13
  def self.send(inputflow_factories, logger)
    inputflow_factories.each { |os_label, version|
      version.each { |version_label, input_flow_servers|
        input_flow_servers[:servers].each_value { |input_flow_server|
          begin
            geo_file_source = "geolocations_#{$staging}.txt"

            raise "flow <#{geo_file_source}> not exist" unless File.exist?(File.join(TMP, geo_file_source))

            geolocations_flow = File.open(File.join(TMP, geo_file_source))
            geo_details = geolocations_flow.read

            response = RestClient.post "http://#{input_flow_server[:ip]}:#{input_flow_server[:port]}/geolocations/geolocations_#{$staging}_#{Date.today.strftime("%Y-%m-%d")}_#{Time.now.hour}.txt",
                                       geo_details,
                                       :content_type => :json,
                                       :accept => :json

            raise response.content if response.code != 200

          rescue Exception => e
            logger.a_log.warn "geolocations flow <#{File.join(TMP, geo_file_source)}> not push to input flow server #{input_flow_server[:ip]}:#{input_flow_server[:port]} : #{e.message}"
          else
            logger.a_log.info "geolocations flow <#{File.join(TMP, geo_file_source)}> push to input flow server #{input_flow_server[:ip]}:#{input_flow_server[:port]}"
          end
        }
      }
    }

  end
end