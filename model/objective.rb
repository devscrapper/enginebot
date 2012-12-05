require 'net/http'
require 'uri'
require File.dirname(__FILE__) + '/../lib/logging'
require File.dirname(__FILE__) + '/../lib/common'
class Objective

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
       :hourly_distribution,
       :website_id

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
      hourly_distribution=nil,
      policy_id=nil,
      website_id=nil)
    #TODO securiser le fait qu'il ne peut y avoir 2 profils pour un website pour un jour donné lors de la creation du profil avec un callback
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
    @hourly_distribution=hourly_distribution
    @website_id=website_id
  end

  def to_json(*a)
    {
        "objective" => {"day(1i)" => Date.parse(@date).year.to_s,
                        "day(2i)" => Date.parse(@date).month.to_s,
                        "day(3i)" => Date.parse(@date).day.to_s,
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
                        "hourly_distribution" => @hourly_distribution,
                        "website_id" => @website_id.to_s
        }
    }

  end

  def count_visits()
    select["count_visits"].to_i
  end

  def landing_pages()
    result = select
    [result["count_visits"].to_i,
     result["direct_medium_percent"].to_i,
     result["organic_medium_percent"].to_i,
     result["referral_medium_percent"].to_i]
  end

  def behaviour()
    result = select
    [result["count_visits"].to_i,
     result["visit_bounce_rate"].to_i,
     result["page_views_per_visit"].to_i,
     result["avg_time_on_site"].to_i,
     result["min_durations"].to_i,
     result["min_pages"].to_i]
  end

  def return_visitor_rate()
    result = select
    [result["count_visits"].to_i,
     result["return_visitor_rate"].to_i]
  end

  def daily_planification()
    result = select
    p result
    [result["count_visits"].to_i,
     result["hourly_distribution"]]
  end

  def save()
    insert
  end

  #private
  def select()
    begin

      url = "http://#{$statupweb_server_ip}:#{$statupweb_server_port}/websites/#{label}/objectives/#{date}.json"
      p url
      resp = Net::HTTP.get_response(URI.parse(url))
      Common.information("getting objective from statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} is success")
      JSON.parse(resp.body)
    rescue Exception => e
      Common.alert("getting objective from statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} failed : #{e.message}", __LINE__)
      {}
    end
  end

  def insert()
    uri = URI("http://#{$statupweb_server_ip}:#{$statupweb_server_port}/websites/#{label}/objectives")
    http = EventMachine::HttpRequest.new(uri).post :body => self.to_json
    http.callback {
      Common.information("saving objective #{@date} for #{@label} in statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} is success")
    }
    http.errback {
      Common.alert("saving objective #{@date} for #{@label} in statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} failed : #{http.state}", __LINE__)
    }
  end
end
