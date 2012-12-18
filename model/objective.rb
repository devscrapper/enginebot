require 'rubygems'
require "em-http-request"
require 'uri'
require 'net/http'
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
       :hourly_distribution

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
      hourly_distribution=nil)

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
  end

  def to_json(*a)
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
                        "hourly_distribution" => @hourly_distribution
        }
    }

  end

  def count_visits()
    select["count_visits"]
  end

  def landing_pages()
    result = select
    [result["count_visits"],
     result["direct_medium_percent"],
     result["organic_medium_percent"],
     result["referral_medium_percent"]]
  end

  def behaviour()
    result = select
    [result["count_visits"],
     result["visit_bounce_rate"],
     result["page_views_per_visit"],
     result["avg_time_on_site"],
     result["min_durations"],
     result["min_pages"]]
  end

  def return_visitor_rate()
    result = select
    [result["count_visits"],
     result["return_visitor_rate"]]
  end

  def daily_planification()
    result = select
    [result["count_visits"],
     result["hourly_distribution"]]
  end

  def save()
    insert
  end

  #private
  def select()
    begin

      url = "http://#{$statupweb_server_ip}:#{$statupweb_server_port}/websites/#{label}/objectives/#{date}/select.json"

      resp = Net::HTTP.get_response(URI.parse(url))

      if  resp.is_a?(Net::HTTPSuccess) and !(resp.body == "null")

          res = JSON.parse(resp.body)
          Common.information("getting objective websites = #{label}, objectives = #{date} from statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} is success")
      else
      if resp.is_a?(Net::HTTPSuccess) and resp.body == "null"

          res = {}
          Common.alert("getting objective websites = #{label}, objectives = #{date} from statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} not found")
      else
      if !resp.is_a?(Net::HTTPSuccess)

          res = {}
          Common.alert("getting objective websites = #{label}, objectives = #{date} from statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} failed : http error : #{resp}")
      end
      end
      end

      res
    rescue Exception => e
      Common.alert("getting  objective websites = #{label}, objectives = #{date} from statupweb from statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} failed : #{e.message}", __LINE__)
      {}
    end
  end

  def insert()

    #TODO : gerer le WARNING: Can't verify CSRF token authenticity
    #TODO : etudier la necessite de faire du https et d'une authentification pour faire l'insertion
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
