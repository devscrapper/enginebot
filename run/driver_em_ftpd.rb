# coding: utf-8
require_relative '../lib/logging'
require_relative '../model/authentification'
require 'yaml'

class FTPDriver
  OUTPUT = File.expand_path(File.join("..", "..", "output"), __FILE__)
  ARCHIVE = File.expand_path(File.join("..", "..", "archive"), __FILE__) #localisation du repertoire d'archive

  @@log_file = File.dirname(__FILE__) + "/../log/" + File.basename(__FILE__, ".rb") + ".log"
  PARAMETERS = File.dirname(__FILE__) + "/../parameter/" + File.basename(__FILE__, ".rb") + ".yml"
  ENVIRONMENT= File.dirname(__FILE__) + "/../parameter/environment.yml"

  attr :user, :pwd, :authentification_server_port, :envir, :logger, :debugging
  #TODO à supprimer,
  def initialize(driver_args=nil)
    @envir = driver_args unless driver_args.nil?
    @envir = "production" if driver_args.nil?
    @debugging = false
    load_parameters
  end

  def authenticate(user, pass, &block)
    @user = user
    @pwd = pass
    begin
      authen = Authentification.new(user, pass)
      check = authen.check(@authentification_server_port)
      @logger.an_event.debug "check authentification #{user}, #{pass} =>  #{check == true}"
      $stdout << "check authentification #{user}, #{pass} =>  #{check == true}" << "\n"
      yield check == true
    rescue Exception => e
      @logger.an_event.error "FTPServer cannot check authentification <#{user}> : #{e.message}"
      $stderr << "FTPServer cannot check authentification <#{user}> : #{e.message}"  << "\n"
      yield false
    end

  end

  def get_file(path, &block)
    begin
      raise "file not found : #{OUTPUT + path}" unless File.exist?(OUTPUT + path)
      file = File.open(OUTPUT + path)

      Authentification.new(@user, @pwd).delete(@authentification_server_port)
      @logger.an_event.debug "push file <#{path}>"
      $stdout << "push file <#{path}>"  << "\n"
      yield file
    rescue Exception => e
      @logger.an_event.error "FTPServer cannot push file <#{path}> : #{e.message}"
      $stderr << "FTPServer cannot push file <#{path}> : #{e.message}" << "\n"
      yield false
    end
  end

  def change_dir(path, &block)
    yield false
  end

  def dir_contents(path, &block)
    yield false
  end

  def bytes(path, &block)
    yield false
  end

  def put_file(path, data, &block)
    yield false
  end

  def delete_file(path, &block)
    begin
      raise "file not found : #{OUTPUT + path}" unless File.exist?(OUTPUT + path)
      FileUtils.mv(OUTPUT + path, ARCHIVE)

      @logger.an_event.debug "move file <#{path}> to archive"
       $stdout << "move file <#{path}> to archive"   << "\n"
      yield true
    rescue Exception => e
      @logger.an_event.error "FTPServer cannot delete file <#{path}> : #{e.message}"
      $stderr << "FTPServer cannot move file <#{path}> : #{e.message}"  << "\n"
      yield false
    end
  end

  def delete_dir(path, &block)
    yield false
  end

  def rename(from, to, &block)
    yield false
  end

  def make_dir(path, &block)
    yield false
  end

  private

  def dir_item(name)
    EM::FTPD::DirectoryItem.new(:name => name, :directory => true, :size => 0)
  end

  def file_item(name, bytes)
    EM::FTPD::DirectoryItem.new(:name => name, :directory => false, :size => bytes)
  end

  private
  def load_parameters()
    begin
      environment = YAML::load(File.open(ENVIRONMENT), "r:UTF-8")
      @envir = environment["staging"] unless environment["staging"].nil?
    rescue Exception => e
      $stderr << "loading parameter file #{ENVIRONMENT} failed : #{e.message}"  << "\n"
    end

    begin
      params = YAML::load(File.open(PARAMETERS), "r:UTF-8")
      @authentification_server_port = params[@envir]["authentification_server_port"] unless params[@envir]["authentification_server_port"].nil?
      @debugging = params[@envir]["debugging"] unless params[@envir]["debugging"].nil?
    rescue Exception => e
      $stderr << "loading parameters file #{PARAMETERS} failed : #{e.message}"  << "\n"
    end
    @logger = Logging::Log.new(self, :staging => @envir, :debugging => @debugging)
    @logger.an_event.info "parameters of ftp server :"
    @logger.an_event.info "authentification server port : #{@authentification_server_port}"
    @logger.an_event.info "debugging : #{@debugging}"
    @logger.an_event.info "staging : #{@envir}"
  end

end

