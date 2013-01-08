require 'rubygems'
require 'eventmachine'
require 'ice_cube'
require 'json'
require 'json/ext'
require File.dirname(__FILE__) + '/../lib/logging'
require File.dirname(__FILE__) + '/../lib/common'
require 'logger'


class Event
  EXECUTE_ALL = "execute_all"
  EXECUTE_ONE = "execute_one"
  SAVE = "save"
  DELETE = "delete"

  attr :key,
       :periodicity,
       :cmd,
       :business


  def initialize(key, cmd, periodicity=nil, business=nil)
    @key = key
    @cmd = cmd
    @periodicity = periodicity
    @business = business
  end

  def to_json(*a)
    {
        "key" => @key,
        "cmd" => @cmd,
        "periodicity" => @periodicity,
        "business" => @business
    }.to_json(*a)
  end

  def to_s(*a)
    {
        "key" => @key,
        "cmd" => @cmd,
    }.to_s(*a)
  end

  def execute(load_server_port)
    begin
      data = {
                "cmd" => @cmd,
                "label" => @key["label"],
                "date_building" => Date.today,
                "data" => @business}
      Common.send_data_to("localhost", load_server_port, data)
    rescue Exception => e
      Common.alert("send cmd #{cmd} for #{@key["label"]} to load_server failed",__LINE__)
      raise
    end
  end
end


class Policy
  BUILDING_OBJECTIVES_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
  BUILDING_OBJECTIVES_HOUR = 2 * IceCube::ONE_HOUR #heure de démarrage est 2h du matin
  attr :label,
       :change_count_visits_percent,
       :change_bounce_visits_percent,
       :direct_medium_percent,
       :organic_medium_percent,
       :referral_medium_percent,
       :website_id,
       :policy_id,
       :account_ga,
       :periodicity

  def initialize(data)
    @label = data["label"]
    @change_count_visits_percent = data["change_count_visits_percent"]
    @change_bounce_visits_percent = data["change_bounce_visits_percent"]
    @direct_medium_percent=data["direct_medium_percent"]
    @organic_medium_percent=data["organic_medium_percent"]
    @referral_medium_percent= data["referral_medium_percent"]
    @website_id=data["website_id"]
    @policy_id=data["policy_id"]
    @account_ga = data["account_ga"]
    @periodicity = data["periodicity"]
  end

  def to_event()

    key = {"policy_id" => @policy_id,
           "label" => @label
    }
    business = {
        "change_count_visits_percent" => @change_count_visits_percent,
        "change_bounce_visits_percent" => @change_bounce_visits_percent,
        "direct_medium_percent" => @direct_medium_percent,
        "organic_medium_percent" => @organic_medium_percent,
        "referral_medium_percent" => @referral_medium_percent,
        "website_id" => @website_id,
        "policy_id" => @policy_id,
        "account_ga" => @account_ga
    }

    #Si demande suppression de la policy alors absence de periodicity et de business
    if @periodicity.nil?
      Event.new(key,
                "Building_objectives")
    else
      periodicity = IceCube::Schedule.from_yaml(@periodicity)
      periodicity.start_time += BUILDING_OBJECTIVES_DAY + BUILDING_OBJECTIVES_HOUR
      periodicity.end_time += BUILDING_OBJECTIVES_DAY
      periodicity.remove_recurrence_rule IceCube::Rule.weekly.day(:sunday)
      periodicity.add_recurrence_rule IceCube::Rule.weekly.until(periodicity.end_time)
      Event.new(key,
                "Building_objectives",
                periodicity.to_yaml,
                business)
    end


  end
end

class Objective
  CHOOSING_LANDING_PAGES_DAY = -1 * IceCube::ONE_DAY
  CHOOSING_LANDING_PAGES_HOUR = 3 * IceCube::ONE_HOUR #heure de démarrage est 3h du matin
  CHOOSING_DEVICE_PLATFORM_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
  CHOOSING_DEVICE_PLATFORM_HOUR = 4 * IceCube::ONE_HOUR #heure de démarrage est 4h du matin
  BUILDING_VISITS_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
  BUILDING_VISITS_HOUR = 5 * IceCube::ONE_HOUR #heure de démarrage est 4h du matin
  START_PUBLISHING_VISITS_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
  START_PUBLISHING_VISITS_HOUR = 22 * IceCube::ONE_HOUR #heure de démarrage est 10h du soir
  END_PUBLISHING_VISITS_DAY = 0 * IceCube::ONE_DAY #on decale d'un  jour j-1
  END_PUBLISHING_VISITS_HOUR = 21 * IceCube::ONE_HOUR #heure de démarrage est 10h du soir
  attr :count_visits,
       :label,
       :building_date,
       :visit_bounce_rate,
       :page_views_per_visit,
       :avg_time_on_site,
       :min_durations,
       :min_pages,
       :hourly_distribution,
       :return_visitor_rate,
       :account_ga,
       :direct_medium_percent,
       :organic_medium_percent,
       :referral_medium_percent


  def initialize(data)
    @count_visits = data["count_visits"]
    @building_date = data["building_date"]
    @label = data["label"]
    @visit_bounce_rate = data["visit_bounce_rate"]
    @page_views_per_visit = data["page_views_per_visit"]
    @avg_time_on_site = data["avg_time_on_site"]
    @min_durations= data["min_durations"]
    @min_pages = data["min_pages"]
    @hourly_distribution = data["hourly_distribution"]
    @return_visitor_rate = data["return_visitor_rate"]
    @direct_medium_percent=data["direct_medium_percent"]
    @organic_medium_percent=data["organic_medium_percent"]
    @referral_medium_percent= data["referral_medium_percent"]
    @account_ga = data["account_ga"]
    @periodicity = data["periodicity"]
  end

  def to_event()
    date_objective = IceCube::Schedule.from_yaml(@periodicity).start_time
    key = {"building_date" => @building_date,
           "label" => @label
    }
    business = {
        "count_visits" => @count_visits
    }

    start_time = date_objective + CHOOSING_DEVICE_PLATFORM_DAY + CHOOSING_DEVICE_PLATFORM_HOUR
    periodicity = IceCube::Schedule.new(start_time, :end_time => start_time)
    periodicity.add_recurrence_rule IceCube::Rule.daily.until(date_objective + CHOOSING_DEVICE_PLATFORM_DAY + CHOOSING_DEVICE_PLATFORM_HOUR)
    choosing_device_platform_event = Event.new(key,
                                               "Choosing_device_platform",
                                               periodicity.to_yaml,
                                               business)


    business = {
        "count_visits" => @count_visits,
        "direct_medium_percent" => @direct_medium_percent,
        "organic_medium_percent" => @organic_medium_percent,
        "referral_medium_percent" => @referral_medium_percent

    }


    start_time = date_objective + CHOOSING_LANDING_PAGES_DAY + CHOOSING_LANDING_PAGES_HOUR
    periodicity = IceCube::Schedule.new(start_time, :end_time => start_time)
    periodicity.add_recurrence_rule IceCube::Rule.daily.until(date_objective + CHOOSING_LANDING_PAGES_DAY + CHOOSING_LANDING_PAGES_HOUR)
    choosing_landing_page_event = Event.new(key,
                                            "Choosing_landing_pages",
                                            periodicity.to_yaml,
                                            business)


    business = {
        "count_visits" => @count_visits,
        "visit_bounce_rate" => @visit_bounce_rate,
        "page_views_per_visit" => @page_views_per_visit,
        "avg_time_on_site" => @avg_time_on_site,
        "min_durations" => @min_durations,
        "min_pages" => @min_pages,
        "hourly_distribution" => @hourly_distribution,
        "return_visitor_rate" => @return_visitor_rate,
        "account_ga" => @account_ga
    }

    start_time = date_objective + BUILDING_VISITS_DAY + BUILDING_VISITS_HOUR
    periodicity = IceCube::Schedule.new(start_time, :end_time => start_time)
    periodicity.add_recurrence_rule IceCube::Rule.daily.until(date_objective + BUILDING_VISITS_DAY + BUILDING_VISITS_HOUR)
    building_visits_event = Event.new(key,
                                      "Building_visits",
                                      periodicity.to_yaml,
                                      business)


    periodicity = IceCube::Schedule.new(date_objective + START_PUBLISHING_VISITS_DAY + START_PUBLISHING_VISITS_HOUR,
    :end_time => date_objective + END_PUBLISHING_VISITS_DAY + END_PUBLISHING_VISITS_HOUR )
    periodicity.add_recurrence_rule IceCube::Rule.hourly.until(date_objective + END_PUBLISHING_VISITS_DAY + END_PUBLISHING_VISITS_HOUR)
    publishing_visits_event = Event.new(key,
                                        "Publishing_visits",
                                        periodicity.to_yaml)
    [choosing_device_platform_event, choosing_landing_page_event, building_visits_event, publishing_visits_event]
  end
end