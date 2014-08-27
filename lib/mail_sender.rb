#!/usr/bin/env ruby -w
# encoding: UTF-8
require 'yaml'
require 'pony'
require_relative 'parameter'

class MailSender


  attr :address,
       :port,
       :user_name,
       :password,
       :from,
       :to,
       :subject,
       :body,
       :logger

  def initialize(from = "mail@localhost.fr", to, subject, body)
    raise ArgumentError, "to is undefine" if  to.nil?
    raise ArgumentError, "subject is undefine" if  subject.nil?
    raise ArgumentError, "body is undefine" if  body.nil?
    @from = from
    @to = to
    @subject = subject
    @body = body
    @logger = Logging::Log.new(self, :staging => "development", :id_file => File.basename(__FILE__, ".rb"), :debugging => true)
    begin
      parameters = Parameter.new(__FILE__)
    rescue Exception => e
      STDERR << e.message
    else
      @address = parameters.address
      @port = parameters.port
      @user_name = parameters.user_name
      @password = parameters.password
      raise ArgumentError, "parameter <address> is undefine" if  @address.nil?
      raise ArgumentError, "parameter <user_name> is undefine" if  @user_name.nil?
      raise ArgumentError, "parameter <password> is undefine" if  @password.nil?
      raise ArgumentError, "parameter <port> is undefine" if  @port.nil?
      @logger.an_event.info "mail #{to_s}"
    end
  end

  def send_html
    send_mail({:html_body => @body})
  end

  def send
    send_mail({:body => @body})
  end

  private

  def send_mail(options)
    begin
      Pony.mail({:to => @to,
                 :via => :smtp,
                 :from => @from,
                 :subject => @subject,
                 :via_options => {
                     :address => @address,
                     :port => @port,
                     :user_name => @user_name,
                     :password => @password,
                     :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
                     :domain => "localhost.localdomain" # the HELO domain provided by the client to the server
                 }
                }.merge!(options))
    rescue Exception => e
      @logger.an_event.error "mail to #{@to} about #{@subject} not send : #{e.message}"
    else
      @logger.an_event.info "mail to #{@to} about #{@subject} send"
    ensure

    end
  end

  def to_s
    "from <#{@from}>\n" +
    "to <#{@to}>\n" +
        "subject <#{@subject}>\n" +
        "body <#{@body}>\n" +
        "smtp <#{@address}>\n" +
        "port <#{@port}>\n"
  end
end