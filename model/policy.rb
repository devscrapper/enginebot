require 'net/http'
require 'uri'
require File.dirname(__FILE__) + '/../lib/logging'
require File.dirname(__FILE__) + '/../lib/common'
class Policy

  attr :label,
       :date

  def initialize(label, date)

     @label = label
    @date = date
  end


  def properties()
    result = select
    [result["change_count_visits_percent"],
     result["change_bounce_visits_percent"],
    result["direct_medium_percent"],
    result["organic_medium_percent"],
    result["referral_medium_percent"],
    ]
  end


  #private
  def select()
    begin
      #http://localhost:3000/websites/epilation-laser-definitive/policies/2012-11-26/select.json
      url = "http://#{$statupweb_server_ip}:#{$statupweb_server_port}/websites/#{@label}/policies/#{@date}/select.json"
      resp = Net::HTTP.get_response(URI.parse(url))
      if  resp.is_a?(Net::HTTPSuccess) and !(resp.body == "null")
          res = JSON.parse(resp.body)
          Common.information("getting policy websites = #{@label}, policies = #{@date} from statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} is success")
      else
      if resp.is_a?(Net::HTTPSuccess) and resp.body == "null"
          res = {}
          Common.alert("getting policy websites = #{@label}, policies = #{@date} from statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} not found")
      else
      if !resp.is_a?(Net::HTTPSuccess)
          res = {}
          Common.alert("getting policy websites = #{@label}, policies = #{@date} from statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} failed : http error : #{resp}")
      end
      end
      end
      res
    rescue Exception => e
      Common.alert("getting policy from statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} failed : #{e.message}", __LINE__)
      {}
    end
  end


end
