require_relative '../../model/building/inputs'
require_relative '../../model/building/chosens'
require_relative '../../model/building/visits'
require_relative '../../model/flow'
require 'rufus-scheduler'
require 'pathname'

include Flowing
include Building
$debugging = true
$staging = "development"
LOG = Pathname.new(File.join(File.dirname(__FILE__), '..', 'log')).realpath
JDD = Pathname.new(File.join(File.dirname(__FILE__), '..', 'jdd')).realpath
INPUT = Pathname.new(File.join(File.dirname(__FILE__), '..', 'input')).realpath
TMP = Pathname.new(File.join(File.dirname(__FILE__), '..', 'tmp')).realpath
OUTPUT = Pathname.new(File.join(File.dirname(__FILE__), '..', 'output')).realpath
ARCHIVE = Pathname.new(File.join(File.dirname(__FILE__), '..', 'archive')).realpath

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
  FileUtils.remove_dir(INPUT)
  FileUtils.mkdir(INPUT)
  FileUtils.remove_dir(TMP)
  FileUtils.mkdir(TMP)
  FileUtils.remove_dir(OUTPUT)
  FileUtils.mkdir(OUTPUT)
  FileUtils.remove_dir(ARCHIVE)
  FileUtils.mkdir(ARCHIVE)
end

#------------------------------------------------------------------------------------------------------------------
#deploiement du jdd vers input
#------------------------------------------------------------------------------------------------------------------
def deploying
  jdd_file = ["website_epilation-laser-definitive_2013-02-24_1.txt",
              "scraping-hourly-daily-distribution_epilation-laser-definitive_2013-04-21_1.txt",
              "scraping-behaviour_epilation-laser-definitive_2013-04-21_1.txt",
              "scraping-traffic-source-landing-page_epilation-laser-definitive_2013-05-03_1.txt",
              "scraping-device-platform-resolution_epilation-laser-definitive_2013-05-05_1.txt",
              "scraping-device-platform-plugin_epilation-laser-definitive_2013-05-05_1.txt"]


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

#------------------------------------------------------------------------------------------------------------------
# construction des inputs en fonction des fichiers qui viennent de statup
#------------------------------------------------------------------------------------------------------------------
def building_inputs
  @input_flow = Flow.from_basename(INPUT, "website_epilation-laser-definitive_2013-02-24_1.txt")
  Inputs.new.Building_matrix_and_pages(@input_flow)

  @input_flow = Flow.from_basename(INPUT, "scraping-hourly-daily-distribution_epilation-laser-definitive_2013-04-21_1.txt")
  Inputs.new.Building_hourly_daily_distribution(@input_flow)

  @input_flow = Flow.from_basename(INPUT, "scraping-behaviour_epilation-laser-definitive_2013-04-21_1.txt")
  Inputs.new.Building_behaviour(@input_flow)

  @input_flow = Flow.from_basename(INPUT, "scraping-traffic-source-landing-page_epilation-laser-definitive_2013-05-03_1.txt")
  pages_in_mem = true
  Inputs.new.Building_landing_pages(@input_flow, pages_in_mem)

  @input_flow = Flow.from_basename(INPUT, "scraping-device-platform-resolution_epilation-laser-definitive_2013-05-05_1.txt")
  Inputs.new.Building_device_platform(@input_flow.label, @input_flow.date)
end

#------------------------------------------------------------------------------------------------------------------
# choix des landing pages et device platforme
#------------------------------------------------------------------------------------------------------------------
def choosing
  Chosens.new.Choosing_landing_pages("epilation-laser-definitive", "2013-05-05", 45, 50, 5, 1390)

  Chosens.new.Choosing_device_platform("epilation-laser-definitive", "2013-05-05", 1390)
end

#------------------------------------------------------------------------------------------------------------------
# construction des visits
#------------------------------------------------------------------------------------------------------------------
def building_visits
  Visits.new("epilation-laser-definitive", "2013-05-05").Building_visits(1390,
                                                                         90,
                                                                         2,
                                                                         120,
                                                                         20,
                                                                         2)

  Visits.new("epilation-laser-definitive", "2013-05-05").Building_planification("21|60|7|60|11|62|80|15|32|79|100|87|88|73|108|85|79|69|55|48|49|52|48|22",
                                                                                1390)

  Visits.new("epilation-laser-definitive", "2013-05-05").Extending_visits(1390, "pppppppppp", 10)


end

#------------------------------------------------------------------------------------------------------------------
# demarrage des ordonnanceur
# le premier cronifie la construction des visits
# le deuxieme diffuse regulierement les visits vers les statupbot
#------------------------------------------------------------------------------------------------------------------
scheduler.cron "00 00 12 * * 1-7 Europe/Paris" do
  cleaning
  deploying
  building_inputs
  choosing
  building_visits
end
p "cronification de la construction des visit is on"
scheduler.every 3600 do
  Visits.new("epilation-laser-definitive", "2013-05-05").Publishing_visits_by_hour(Date.today)
end

p "diffusion des visits is on"
scheduler.join

exit