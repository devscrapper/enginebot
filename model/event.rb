require 'rubygems'
require 'eventmachine'
require 'json'
require 'json/ext'
require File.dirname(__FILE__) + '/../lib/logging'
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

  def execute(load_server_port)
    begin
      s = TCPSocket.new "localhost", load_server_port
      data = {
          "cmd" => @cmd,
          "label" => @key["label"],
          "date_building" => Date.today,
          "data" => @business}
      p data
      s.puts JSON.generate(data)
      s.close
      p "send to load_server localhost:#{load_server_port} "
    rescue Exception => e
      p "failed to send to load_server localhost:#{load_server_port} "
    end
  end
end


class Policy
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
    cmd = "Building_objectives"
    periodicity = @periodicity
    Event.new(key, cmd, periodicity, business)
  end
end

class Objective
  attr :count_visit,
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
    @count_visit = data["count_visit"]
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
    key = {"building_date" => @building_date,
           "label" => @label
    }
    business = {
        "count_visit" => @count_visit
    }
    choosing_device_platform_event = Event.new(key, "Choosing_device_platform", @periodicity, business)


    business = {
        "count_visit" => @count_visit,
        "direct_medium_percent" => @direct_medium_percent,
        "organic_medium_percent" => @organic_medium_percent,
        "referral_medium_percent" => @referral_medium_percent

    }
    choosing_landing_page_event = Event.new(key, "Choosing_landing_pages", @periodicity, business)


    business = {
        "count_visit" => @count_visit,
        "visit_bounce_rate" => @visit_bounce_rate,
        "page_views_per_visit" => @page_views_per_visit,
        "avg_time_on_site" => @avg_time_on_site,
        "min_durations" => @min_durations,
        "min_pages" => @min_pages,
        "hourly_distribution" => @hourly_distribution,
        "return_visitor_rate" => @return_visitor_rate,
        "account_ga" => @account_ga
    }
    building_visits_event = Event.new(key, "Building_visits", @periodicity, business)

    [choosing_device_platform_event, choosing_landing_page_event,building_visits_event]
  end
end