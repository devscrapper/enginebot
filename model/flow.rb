require 'socket'
require File.dirname(__FILE__) + '/../lib/common'
require 'ruby-progressbar'

#TODO publier vers les autres projet
class Flow
  class FlowException < StandardError;
  end
  include Common
  include Enumerable

  SEPARATOR = "_"
  ARCHIVE = File.dirname(__FILE__) + "/../archive/"

  attr :descriptor

  attr_accessor :dir,
                :label,
                :type_flow,
                :date,
                :vol,
                :ext

#----------------------------------------------------------------------------------------------------------------
# class methods
#----------------------------------------------------------------------------------------------------------------
  def self.from_basename(dir, basename)
    ext = File.extname(basename)
    basename = File.basename(basename, ext)
    basename_splitted = basename.split(SEPARATOR)
    type_flow = basename_splitted[0]
    label = basename_splitted[1]
    date = basename_splitted[2]
    vol = basename_splitted[3]

    Flow.new(dir, type_flow, label, date, vol, ext)
  end

  def self.from_absolute_path(absolute_path)
    dir = File.dirname(absolute_path)
    basename = File.basename(absolute_path)
    Flow.from_basename(dir, basename)
  end

#----------------------------------------------------------------------------------------------------------------
# instance methods
#----------------------------------------------------------------------------------------------------------------

  def initialize(dir, type_flow, label, date, vol=nil, ext=".txt")
    @dir = dir
    @type_flow = type_flow
    @label = label
    @date = date.strftime("%Y-%m-%d") if date.is_a?(Date)
    @date = date unless date.is_a?(Date)
    @vol = vol if vol.is_a?(String)
    @vol = vol.to_s unless vol.is_a?(String)
    @ext = ext
    raise FlowException, "Flow not initialize" unless @dir && @type_flow && @label && @date && @ext
  end


  def absolute_path
    File.join(@dir, basename)
  end

  def basename
    basename = @type_flow + SEPARATOR + @label + SEPARATOR + @date
    basename += SEPARATOR + @vol unless @vol.nil?
    basename += @ext
    basename
  end

  def vol=(vol)
    @vol = vol if vol.is_a?(String)
    @vol = vol.to_s unless vol.is_a?(String)
  end

  def write(data)
    @descriptor = File.open(absolute_path, "w:UTF-8") if @descriptor.nil?
    @descriptor.sync = true
    @descriptor.write(data)
  end

  def append(data)
    @descriptor = File.open(absolute_path, "a:UTF-8") if @descriptor.nil?
    @descriptor.sync = true
    @descriptor.write(data)
  end

  def close
    @descriptor.close if @descriptor.nil?
  end

  def count_lines(eofline)
    raise FlowException, "Flow <#{absolute_path}> not exist" unless exist?
    File.foreach(absolute_path, eofline, encoding: "BOM|UTF-8:-").inject(0) { |c| c+1 }
  end

  def total_lines(eofline)
    total_lines = 0
    volumes.each { |flow| total_lines += flow.count_lines(eofline) }
    total_lines
  end
  def descriptor
    raise FlowException, "Flow <#{absolute_path}> not exist" unless exist?
    @descriptor = File.open(absolute_path, "BOM|UTF-8:-") if @descriptor.nil?
    @descriptor
  end

  def readline
    raise FlowException, "Flow <#{absolute_path}> not exist" unless exist?
    @descriptor = File.open(absolute_path, "BOM|UTF-8:-") if @descriptor.nil?
    @descriptor.readline()
  end

  def exist?
    File.exist?(absolute_path)
  end

  def delete
    File.delete(absolute_path) if exist?
  end

  def cp(to_path)
    raise FlowException, "target <#{to_path}> is not valid" unless File.exists?(to_path) && File.directory?(to_path)
    raise FlowException, "Flow <#{absolute_path}> not exist" unless exist?
    FileUtils.cp(absolute, to_path)
  end

  def last()
    #TODO rework en utilisant la methode volumes
    return basename if exist?
    volum = "#{SEPARATOR}#{@vol}" unless @vol.nil?
    volum = "" if @vol.nil?
    max_time = Time.new(2001, 01, 01)
    chosen_file = nil
    Dir.glob("#{@dir}#{@type_flow}#{SEPARATOR}#{@label}#{SEPARATOR}*#{volum}#{@ext}").each { |file|
      if File.ctime(file) > max_time
        max_time = File.ctime(file)
        chosen_file = file
      end
    }
    chosen_file
  end

  def archive
    raise FlowException, "Flow <#{absolute_path}> not exist" unless exist?
    FileUtils.mv(absolute_path, ARCHIVE, :force => true)
  end

  def put(ip_to, port_to, ip_ftp_server, port_ftp_server, user, pwd, last_volume = false)
    data = {"ip_ftp_server" => ip_ftp_server,
            "port_ftp_server" => port_ftp_server,
            "user" => user,
            "pwd" => pwd,
            "cmd" => CMD,
            "type_flow" => @type_flow,
            "basename" => basename,
            "last_volume" => last_volume,
    }
    begin
      data_to_json = JSON.generate(data).strip
      s = TCPSocket.new ip_to, port_to
      s.puts data_to_json
      s.close
    rescue Exception => e
      alert("put flow <#{basename}> to #{ip_to}:#{port_to} failed : #{e.message}")
      raise FlowException
    end
  end

  def get(ip_from, port_from, user, pwd)
    begin
      ftp = Net::FTP.new
      ftp.connect(ip_from, port_from)
      ftp.login(user, pwd)
      ftp.gettextfile(basename, absolute_path)
      ftp.delete(basename)
      ftp.close
      information("get flow <#{basename}> from #{ip_from}:#{port_from}")
    rescue Exception => e
      alert("get flow <#{basename}> from #{ip_from}:#{port_from} failed : #{e.message}")
      raise FlowException, e.message
    end
  end

  def volumes
    #renvoi un array contenant les flow de tous les volumes
    raise FlowException, "Flow <#{absolute_path}> not exist" unless exist?
    array = []
    crt = self
    vol = 1
    crt.vol = vol
    while crt.exist?
      array << crt
      crt = Flow.from_absolute_path(crt.absolute_path)
      vol += 1
      crt.vol = vol
    end
    array
  end

  def volumes?
    #renvoi le nombre de volume
    raise FlowException, "Flow <#{absolute_path}> not exist" unless exist?
    count = 0
    crt = self
    vol = 1
    crt.vol = vol
    while crt.exist?
      count += 1
      crt = Flow.from_absolute_path(crt.absolute_path)
      vol += 1
      crt.vol = vol
    end
    count
  end


  def load_to_array(eofline, class_definition=nil)
    # class_definition est une class
    # si class_definition est nil alors on range la ligne dans le array
    # si class_definition n'est pas nil alors on range une instance de la class construite à partir de la ligne, dans le array
    raise FlowException, "Flow <#{absolute_path}> not exist" unless exist?
    raise FlowException, "eofline not define" if eofline.nil?
    array = []
    p = ProgressBar.create(:title => "Loading #{basename} file", :length => 180, :starting_at => 0, :total => total_lines(eofline), :format => '%t, %c/%C, %a|%w|')
    volumes.each { |flow|
      IO.foreach(flow.absolute_path, eofline, encoding: "BOM|UTF-8:-") { |line|
        array << class_definition.new(line) unless class_definition.nil?
        array << line if class_definition.nil?
        p.increment
      }
    }
    array
  end
end