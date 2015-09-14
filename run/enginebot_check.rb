require_relative '../model/flowing/flow2task/inputs'
require_relative '../model/tasking/event2task/inputs'
require_relative '../model/tasking/event2task/chosens'
require_relative '../model/tasking/event2task/visits'
require_relative '../model/tasking/event2task/objectives'
require_relative '../model/flow'
require 'rufus-scheduler'
require 'pathname'
include Flowing
include Tasking
$debugging = true
$staging = "development"
$calendar_server_port = 9104
$scraperbot_calendar_server_port = 9154
$scraperbot_calendar_server_ip = "localhost"
# ces variables permettent d'utiliser les serveurs task pour tester si == true, sinon en direct
TASK_SERVER = false
LOG = Pathname.new(File.join(File.dirname(__FILE__), '..', 'log')).realpath
JDD = Pathname.new(File.join(File.dirname(__FILE__), '..', 'jdd')).realpath
INPUT = Pathname.new(File.join(File.dirname(__FILE__), '..', 'input'))
TMP = Pathname.new(File.join(File.dirname(__FILE__), '..', 'tmp'))
OUTPUT = Pathname.new(File.join(File.dirname(__FILE__), '..', 'output'))
ARCHIVE = Pathname.new(File.join(File.dirname(__FILE__), '..', 'archive'))
CRON = "58 16 * * 1-7" # mm hh
#------------------------------------------------------------------------------------------------------------------
#creation du scheduler
#------------------------------------------------------------------------------------------------------------------
scheduler = Rufus::Scheduler.start_new
#------------------------------------------------------------------------------------------------------------------
#nettoyage des répertoires
#------------------------------------------------------------------------------------------------------------------
def cleaning
  FileUtils.rm Dir.glob(File.join(LOG, "#{File.basename(__FILE__, ".rb")}.*"))
  @logger = Logging::Log.new(self, :staging => $staging, :id_file => File.basename(__FILE__, ".rb"), :debugging => $debugging)
  FileUtils.remove_dir(INPUT, true) if File.exist?(INPUT)
  FileUtils.mkdir(INPUT)
  FileUtils.remove_dir(TMP, true) if File.exist?(TMP)
  begin
    FileUtils.mkdir(TMP)
  rescue
  end

  FileUtils.remove_dir(OUTPUT, true) if File.exist?(OUTPUT)
  FileUtils.mkdir(OUTPUT)
  FileUtils.remove_dir(ARCHIVE, true) if File.exist?(ARCHIVE)
  begin
    FileUtils.mkdir(ARCHIVE)
  rescue
  end
end

#------------------------------------------------------------------------------------------------------------------
#deploiement du jdd vers input
#------------------------------------------------------------------------------------------------------------------
def deploying(label, today, policy)
  jdd_file = ["scraping-website_#{policy}_#{label}_#{today}_1.txt",
              "scraping-hourly-daily-distribution_#{policy}_#{label}_2013-04-21_1.txt",
              "scraping-behaviour_#{policy}_#{label}_2013-04-21_1.txt",
              "scraping-traffic-source-organic_#{policy}_#{label}_#{today}_1.txt",
              "scraping-traffic-source-referral_#{policy}_#{label}_#{today}_1.txt",
              "scraping-device-platform-resolution_#{policy}_#{label}_#{today}_1.txt",
              "scraping-device-platform-plugin_#{policy}_#{label}_#{today}_1.txt"] if policy == "traffic"

  jdd_file = ["scraping-hourly-daily-distribution_#{policy}_#{label}_2013-04-21_1.txt",
              "scraping-behaviour_#{policy}_#{label}_2013-04-21_1.txt",
              "scraping-traffic-source-organic_#{policy}_#{label}_#{today}_1.txt",
              "scraping-device-platform-resolution_#{policy}_#{label}_#{today}_1.txt",
              "scraping-device-platform-plugin_#{policy}_#{label}_#{today}_1.txt"] if policy == "rank"

  count_files = 0
  jdd_file.each { |file|
    count_files += Flow.from_basename(JDD, file).volumes?
  }

  p = ProgressBar.create(:title => "Deploying JDD #{policy}", :length => 180, :starting_at => 0, :total => count_files, :format => '%t, %c/%C, %a|%w|')
  jdd_file.each { |file|
    Flow.from_basename(JDD, file).volumes.each { |vol|
      vol.cp(INPUT)
      p.increment
    }
  }
end


#------------------------------------------------------------------------------------------------------------------
# construction des inputs en fonction des fichiers qui viennent de statup
#------------------------------------------------------------------------------------------------------------------
def building_inputs(label, today, policy)

  @input_flow = Flow.from_basename(INPUT, "scraping-hourly-daily-distribution_#{policy}_#{label}_2013-04-21_1.txt")
  Flowing::Inputs.new(label, today, policy).Building_hourly_daily_distribution(@input_flow)

  @input_flow = Flow.from_basename(INPUT, "scraping-behaviour_#{policy}_#{label}_2013-04-21_1.txt")
  Flowing::Inputs.new(label, today, policy).Building_behaviour(@input_flow)

  Flowing::Inputs.new(label, today, policy).Building_device_platform

  if policy == "traffic"
    Inputs.new(label, today, policy).Building_landing_pages(:direct)
    Inputs.new(label, today, policy).Building_landing_pages(:referral)
  end
  Inputs.new(label, today, policy).Building_landing_pages(:organic)


end


#------------------------------------------------------------------------------------------------------------------
# demarrage des ordonnanceur
# le premier cronifie la construction des visits
# le deuxieme diffuse regulierement les visits vers les statupbot
#------------------------------------------------------------------------------------------------------------------

label = "epilation-laser-definitive"
today = "2015-02-27"
@logger = Logging::Log.new(self, :staging => "development", :debugging => true)
datas = [
    {:website_id => 1, :policy_id => 1, :policy_type => "traffic",
     :direct_medium_percent => 45,
     :organic_medium_percent => 50,
     :referral_medium_percent => 5,
     :count_visits => 1390,
     :visit_bounce_rate => 65,
     :page_views_per_visit => 2,
     :avg_time_on_site => 120,
     :min_durations => 20,
     :min_pages => 2,
     :hourly_distribution => "21|60|7|60|11|62|80|15|32|79|100|87|88|73|108|85|79|69|55|48|49|52|48|22",
     :advertisers => ["adsense"],
     :advertising_percent => 1
    },
    {:website_id => 1, :policy_id => 2, :policy_type => "rank",
     :direct_medium_percent => 0,
     :organic_medium_percent => 100,
     :referral_medium_percent => 0,
     :count_visits_per_day => 20,
     :count_visits => 20,
     :visit_bounce_rate => 0,
     :page_views_per_visit => 2,
     :avg_time_on_site => 120,
     :min_durations => 20,
     :min_pages => 2,
     :hourly_distribution => "20|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0" ,
     :advertisers => ["none"],
     :advertising_percent => 0
    }
]


 cleaning

datas.each { |data|
 deploying(label, today, data[:policy_type])
 building_inputs(label, today, data[:policy_type])
  if TASK_SERVER
    #------------------------------------------------------------------------------------------------------------------
    # TASK_SERVER
    #------------------------------------------------------------------------------------------------------------------
    case data[:policy_type]
      when "traffic"
        Task.new("Building_objectives", {"website_id" => data[:website_id],
                                         "policy_id" => data[:policy_id],
                                         "policy_type" => data[:policy_type],
                                         "website_label" => label,
                                         "date_building" => today,
                                         "change_count_visits_percent" => 10, #change_count_visits_percent
                                         "change_bounce_visits_percent" => 1, #change_bounce_visits_percent
                                         "direct_medium_percent" => data[:direct_medium_percent],
                                         "organic_medium_percent" => data[:organic_medium_percent],
                                         "referral_medium_percent" => data[:referral_medium_percent],
                                         "advertising_percent" =>  data[:advertising_percent], #advertising_percent
                                         "advertisers" =>  data[:advertisers],
                                         "url_root" => "http://www.epilation-laser-definitive.info/"}).execute
      when "rank"
        Task.new("Building_objectives", {"website_id" => data[:website_id],
                                         "policy_id" => data[:policy_id],
                                         "policy_type" => data[:policy_type],
                                         "website_label" => label,
                                         "date_building" => today,
                                         "count_visits_per_day" => data[:count_visits_per_day],
                                         "advertising_percent" =>  data[:advertising_percent], #advertising_percent
                                         "advertisers" =>  data[:advertisers],
                                         "url_root" => "http://www.epilation-laser-definitive.info/"}).execute

    end


    Task.new("Choosing_landing_pages", {"website_id" => data[:website_id],
                                        "policy_id" => data[:policy_id],
                                        "policy_type" => data[:policy_type],
                                        "website_label" => label,
                                        "date_building" => today,
                                        "direct_medium_percent" => data[:direct_medium_percent],
                                        "organic_medium_percent" => data[:organic_medium_percent],
                                        "referral_medium_percent" => data[:referral_medium_percent],
                                        "count_visits" => data[:count_visits]}).execute

    Task.new("Choosing_device_platform", {"website_id" => data[:website_id],
                                          "policy_id" => data[:policy_id],
                                          "policy_type" => data[:policy_type],
                                          "website_label" => label,
                                          "date_building" => today,
                                          "count_visits" => data[:count_visits]}).execute

    # comme le déclenchement avec le serveur est asynchrone, on temporise dans le fichier n'ets pas terminé
    $stdout << "sleeping for choosing #{data[:policy_type]}\n"
    sleep 5
    while Flow.new(TMP, "chosen-landing-pages", data[:policy_type], label, today).count_lines(EOFLINE) < data[:count_visits].to_i
      sleep 5
    end

    Task.new("Building_visits", {"website_id" => data[:website_id],
                                 "policy_id" => data[:policy_id],
                                 "policy_type" => data[:policy_type],
                                 "website_label" => label,
                                 "date_building" => today,
                                 "count_visits" => data[:count_visits],
                                 "visit_bounce_rate" => data[:visit_bounce_rate],
                                 "page_views_per_visit" => data[:page_views_per_visit],
                                 "avg_time_on_site" => data[:avg_time_on_site],
                                 "min_durations" => data[:min_durations],
                                 "min_pages" => data[:min_pages],
                                 "hourly_distribution" => data[:hourly_distribution],
                                 "advertisers" => data[:advertisers],
                                 "advertising_percent" => data[:advertising_percent]
                              }).execute


    # comme le déclenchement avec le serveur est asynchrone, pour attendre que les fichiers final- soit à jour
    sleep 5 ; $stdout << "sleeping for publishing #{data[:policy_type]}\n"
    while !Flow.new(TMP, "final-visits", data[:policy_type], label, today).volume_exist?(24)
      sleep 5
    end

    Task.new("Publishing_visits", {"website_id" => data[:website_id],
                                 "policy_id" => data[:policy_id],
                                 "policy_type" => data[:policy_type],
                                 "website_label" => label,
                                 "date_building" => today,
                                 }).execute
    #    Visits.new(label, today, data[:policy_type]).Publishing_visits_by_hour(Date.today)
  else
    #------------------------------------------------------------------------------------------------------------------
    # NO TASK_SERVER
    #------------------------------------------------------------------------------------------------------------------
    case data[:policy_type]
      when "traffic"

        Objectives.new(label,
                       today,
                       data[:policy_id],
                       data[:website_id],
                       data[:policy_type]).Building_objectives_traffic(10,
                                                                       1,
                                                                       data[:direct_medium_percent],
                                                                       data[:organic_medium_percent],
                                                                       data[:referral_medium_percent],
                                                                       1,
                                                                       ["adsense"],
                                                                       "http://www.epilation-laser-definitive.info/")
      when "rank"
        Objectives.new(label,
                       today,
                       data[:policy_id],
                       data[:website_id],
                       data[:policy_type]).Building_objectives_rank(data[:count_visits_per_day],
                                                                    "http://centre.epilation-laser-definitive.info/11685.htm")
    end

    Chosens.new(label, today, data[:policy_type]).Choosing_landing_pages(data[:direct_medium_percent],
                                                                         data[:organic_medium_percent],
                                                                         data[:referral_medium_percent],
                                                                         data[:count_visits])

    Chosens.new(label, today, data[:policy_type]).Choosing_device_platform(data[:count_visits])

    Visits.new(label, today, data[:policy_type]).Building_visits(data[:count_visits],
                                                                 data[:visit_bounce_rate],
                                                                 data[:page_views_per_visit],
                                                                 data[:avg_time_on_site],
                                                                 data[:min_durations],
                                                                 data[:min_pages])

    Visits.new(label, today, data[:policy_type]).Building_planification(data[:hourly_distribution], data[:count_visits])
    Visits.new(label, today, data[:policy_type]).Extending_visits(data[:count_visits], 1, ["adsense"])
    Visits.new(label, today, data[:policy_type]).Reporting_visits
    Visits.new(label, today, data[:policy_type]).Publishing_visits_by_hour(Date.today)
  end


}


exit