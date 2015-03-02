require_relative '../model/building/inputs'
require_relative '../model/building/chosens'
require_relative '../model/building/visits'
require_relative '../model/building/objectives'
require_relative '../model/flow'
require 'rufus-scheduler'
require 'pathname'

include Flowing
include Building
$debugging = true
$staging = "development"
$calendar_server_port = 9104
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
  logger = Logging::Log.new(self, :staging => $staging, :id_file => File.basename(__FILE__, ".rb"), :debugging => $debugging)
  FileUtils.remove_dir(INPUT) if File.exist?(INPUT)
  FileUtils.mkdir(INPUT)
  FileUtils.remove_dir(TMP) if File.exist?(TMP)
  FileUtils.mkdir(TMP)
  FileUtils.remove_dir(OUTPUT) if File.exist?(OUTPUT)
  FileUtils.mkdir(OUTPUT)
  FileUtils.remove_dir(ARCHIVE) if File.exist?(ARCHIVE)
  FileUtils.mkdir(ARCHIVE)
end

#------------------------------------------------------------------------------------------------------------------
#deploiement du jdd vers input
#------------------------------------------------------------------------------------------------------------------
def deploying(label, today)
  jdd_file = ["scraping-website_#{label}_#{today}_1.txt",
              "scraping-hourly-daily-distribution_#{label}_2013-04-21_1.txt",
              "scraping-behaviour_#{label}_2013-04-21_1.txt",
              "scraping-traffic-source-organic_#{label}_#{today}_1.txt",
              "scraping-traffic-source-referral_#{label}_#{today}_1.txt",
              "scraping-device-platform-resolution_#{label}_#{today}_1.txt",
              "scraping-device-platform-plugin_#{label}_#{today}_1.txt"]


  count_files = 0
  jdd_file.each { |file|
    count_files += Flow.from_basename(JDD, file).volumes?
  }

  p = ProgressBar.create(:title => "Deploying JDD", :length => 180, :starting_at => 0, :total => count_files, :format => '%t, %c/%C, %a|%w|')
  jdd_file.each { |file|
    Flow.from_basename(JDD, file).volumes.each { |vol|
      vol.cp(INPUT)
      p.increment
    }
  }
end


def building_objectives(label, today, root_url)
  Objectives.new.Building_objectives(label,
                                     today,
                                     10,
                                     1,
                                     50,
                                     50,
                                      0, # aucun referral n'est scrapper de GA ; attend le service de backlink
                                      1,
                                      ["adsense"],
                                     1,
                                     1,
                                     root_url)
end

#------------------------------------------------------------------------------------------------------------------
# construction des inputs en fonction des fichiers qui viennent de statup
#------------------------------------------------------------------------------------------------------------------
def building_inputs(label, today)
  Inputs.new.Building_matrix_and_pages(label, today)

  @input_flow = Flow.from_basename(INPUT, "scraping-hourly-daily-distribution_#{label}_2013-04-21_1.txt")
  Inputs.new.Building_hourly_daily_distribution(@input_flow)

  @input_flow = Flow.from_basename(INPUT, "scraping-behaviour_#{label}_2013-04-21_1.txt")
  Inputs.new.Building_behaviour(@input_flow)

  Inputs.new.Building_landing_pages(label, today)

  Inputs.new.Building_device_platform(label, today)
end

#------------------------------------------------------------------------------------------------------------------
# choix des landing pages et device platforme
#------------------------------------------------------------------------------------------------------------------
def choosing(label, today)
  Chosens.new.Choosing_landing_pages(label, today, 45, 50, 5, 1390)

  Chosens.new.Choosing_device_platform(label, today,  1390)
end

#------------------------------------------------------------------------------------------------------------------
# construction des visits
#------------------------------------------------------------------------------------------------------------------
def building_visits (label, today)
 Visits.new(label, today,).Building_visits(1390,
                                                                         65,
                                                                         2,
                                                                         120,
                                                                         20,
                                                                         2)

 Visits.new(label, today,).Building_planification("21|60|7|60|11|62|80|15|32|79|100|87|88|73|108|85|79|69|55|48|49|52|48|22",
                                                                               1390)

 Visits.new(label, today,).Extending_visits(1390, 10, 1, ["adsense"])

  Visits.new(label, today,).Reporting_visits


end

#------------------------------------------------------------------------------------------------------------------
# demarrage des ordonnanceur
# le premier cronifie la construction des visits
# le deuxieme diffuse regulierement les visits vers les statupbot
#------------------------------------------------------------------------------------------------------------------
#scheduler.cron CRON do
label = "epilation-laser-definitive"
today = "2015-02-27"
root_url = "http://www.epilation-laser-definitive.info/"
cleaning
deploying(label, today)
building_inputs(label, today)
building_objectives(label, today, root_url)
choosing(label, today)
building_visits(label, today)
Visits.new(label, today).Publishing_visits_by_hour()
#end
p "cronification de la construction des visit is on"
scheduler.every 3600 do
  Visits.new(label, today).Publishing_visits_by_hour(Date.today)
end

p "diffusion des visits is on"
scheduler.join

exit