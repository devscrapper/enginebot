require 'net/http'
require File.dirname(__FILE__) + '/../lib/logging'
require File.dirname(__FILE__) + '/../lib/common'
class Website
  attr :label

  def initialize(label)
    @label = label
  end


  def account_ga()
    select["account_ga"]
  end


  #private
  def select()
    begin
      url = "http://#{$statupweb_server_ip}:#{$statupweb_server_port}/websites/#{label}/select.json" #"...#{URI.encode(@label)}/#{@date}...."
      resp = Net::HTTP.get_response(URI.parse(url))
      if  resp.is_a?(Net::HTTPSuccess) and !(resp.body == "null")
        res = JSON.parse(resp.body)
        Common.information("getting website websites = #{@label}, objectives = #{@date} from statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} is success")
      else
        if resp.is_a?(Net::HTTPSuccess) and resp.body == "null"
          res = {}
          Common.alert("getting website websites = #{@label}, objectives = #{@date} from statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} not found")
        else
          if !resp.is_a?(Net::HTTPSuccess)
            res = {}
            Common.alert("getting website websites = #{@label}, objectives = #{@date} from statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} failed : http error : #{resp}")
          end
        end
      end
      res
    rescue Exception => e
      Common.alert("getting website from statupweb #{$statupweb_server_ip}:#{$statupweb_server_port} failed : #{e.message}")
      {}
    end

  end


end
