require 'ice_cube'
require_relative '../../model/communication'

class Objective
  class ObjectiveException < StandardError
  end
  SEPARATOR4="|"
  attr :label,
       :date,
       :count_visits,
       :visit_bounce_rate,
       :return_visitor_rate,
       :avg_time_on_site,
       :page_views_per_visit,
       :min_durations,
       :min_pages,
       :direct_medium_percent,
       :referral_medium_percent,
       :organic_medium_percent,
       :advertising_percent,
       :advertisers,
       :hourly_distribution,
       :policy_id,
       :website_id,
       :url_root

  def initialize(label, date,
      count_visits =nil,
      visit_bounce_rate=nil,
      return_visitor_rate=nil,
      avg_time_on_site=nil,
      page_views_per_visit=nil,
      min_durations=nil,
      min_pages=nil,
      direct_medium_percent=nil,
      referral_medium_percent=nil,
      organic_medium_percent=nil,
      advertising_percent=nil,
      advertisers = nil,
      hourly_distribution=nil,
      policy_id=nil,
      website_id=nil,
  url_root = nil)

    @date = date
    @label = label
    @count_visits = count_visits
    @visit_bounce_rate=visit_bounce_rate
    @return_visitor_rate=return_visitor_rate
    @avg_time_on_site=avg_time_on_site
    @page_views_per_visit=page_views_per_visit
    @min_durations=min_durations
    @min_pages=min_pages
    @direct_medium_percent=direct_medium_percent
    @referral_medium_percent=referral_medium_percent
    @organic_medium_percent=organic_medium_percent
    @advertising_percent=advertising_percent
    @advertisers = advertisers
    @hourly_distribution=translate_to_count_visits_target(hourly_distribution, count_visits)
    @policy_id = policy_id
    @website_id = website_id
    @url_root = url_root
  end

  def to_db(*a)
    {
        "objective" => {"day(1i)" => @date.year.to_s,
                        "day(2i)" => @date.month.to_s,
                        "day(3i)" => @date.day.to_s,
                        "count_visits" => @count_visits.to_s,
                        "visit_bounce_rate" => @visit_bounce_rate.to_s,
                        "return_visitor_rate" => @return_visitor_rate.to_s,
                        "avg_time_on_site" => @avg_time_on_site.to_s,
                        "min_durations" => @min_durations.to_s,
                        "min_pages" => @min_pages.to_s,
                        "page_views_per_visit" => @page_views_per_visit.to_s,
                        "direct_medium_percent" => @direct_medium_percent.to_s,
                        "organic_medium_percent" => @organic_medium_percent.to_s,
                        "referral_medium_percent" => @referral_medium_percent.to_s,
                        "advertising_percent" => @advertising_percent.to_s,
                        "advertisers" => @advertisers,
                        "hourly_distribution" => @hourly_distribution,
                        "policy_id" => @policy_id,
                        "website_id" => @website_id
        }
    }
  end

  def to_json(*a)
    {
        "building_date" => @date,
        "label" => @label,
        "periodicity" => IceCube::Schedule.new(Time.local(@date.year, @date.month, @date.day),
                                               :end_time => Time.local(@date.year, @date.month, @date.day)).to_yaml,
        "count_visits" => @count_visits,
        "visit_bounce_rate" => @visit_bounce_rate,
        "return_visitor_rate" => @return_visitor_rate,
        "avg_time_on_site" => @avg_time_on_site,
        "min_durations" => @min_durations,
        "min_pages" => @min_pages,
        "page_views_per_visit" => @page_views_per_visit,
        "direct_medium_percent" => @direct_medium_percent,
        "organic_medium_percent" => @organic_medium_percent,
        "referral_medium_percent" => @referral_medium_percent,
        "advertising_percent" => @advertising_percent,
        "advertisers" => @advertisers,
        "hourly_distribution" => @hourly_distribution,
        "url_root" => @url_root
    }
  end

  def send_to_db(where_ip, where_port)
    #TODO send to DB à faire
    #TODO : gerer le WARNING: Can't verify CSRF token authenticity
    #TODO : etudier la necessite de faire du https et d'une authentification pour faire l'insertion
    #uri = URI("http://#{$statupweb_server_ip}:#{$statupweb_server_port}/websites/#{label}/objectives")
    #http = EventMachine::HttpRequest.new(uri).post :body => self.to_db
    #http.callback {
    #  Common.information("saving objective #{@date} for #{@label} in statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} is success")
    #}
    #http.errback {
    #  Common.alert("saving objective #{@date} for #{@label} in statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} failed : #{http.state}", __LINE__)
    #}


    #begin
    #  options = {"path" => "/objectives/create",
    #             "scheme" => "http"}
    #  Information.new(self.to_db).send_to(where_ip, where_port, options)
    #rescue Exception => e
    #  raise ObjectiveException, e.message
    #end
  end


  def send_to_calendar(hostname, where_port)
    data = {"cmd" => "save",
            "object" => self.class.name,
            "data" => self.to_json}
    begin
      Information.new(data).send_to(hostname, where_port)
    rescue Exception => e
      raise ObjectiveException, e.message
      #TODO gérer les rebus quand le calendar server n'est pas joignable
    end
  end



  def translate_to_count_visits_target(distribution, count_visits_of_day_target)
    count_visits_of_day_origin = 0
    count_visits_of_day = distribution.split(SEPARATOR4)
    count_visits_of_day.each { |count_visit_per_hour| count_visits_of_day_origin += count_visit_per_hour.to_i }
    count_visits_of_day.map! { |count_visit_per_hour| count_visit_per_hour.to_i * count_visits_of_day_target / count_visits_of_day_origin }
    count_visits_of_day_inter = 0
    count_visits_of_day.each { |count_visit_per_hour| count_visits_of_day_inter += count_visit_per_hour.to_i }
    (count_visits_of_day_target - count_visits_of_day_inter).times { count_visits_of_day[rand(count_visits_of_day.size-1)] += 1 }
    count_visits_of_day.join(SEPARATOR4)
  end
end
