require 'rubygems'
require 'eventmachine'
require 'json'
require 'json/ext'
require File.dirname(__FILE__) + '/../lib/logging'
require 'logger'

# ---------------------------------------------------------------------------------------------------------------------
# TODO :

# ---------------------------------------------------------------------------------------------------------------------
class Event
  @@log_file = File.dirname(__FILE__) + "/../log/" + File.basename(__FILE__, ".rb") + ".log"
  attr :label,
       :periodicity,
       :what,
       :cmd,
       :id


  def initialize(new_event)
    @label = new_event["label"] unless new_event["label"].nil?
    @what = new_event["what"] unless new_event["what"].nil?
    @id = new_event["id"] unless new_event["id"].nil?
    @periodicity = new_event["periodicity"] unless new_event["periodicity"].nil?
    #TODO mettre en oeuvre les regles de planificiation du Calendar : quel jour quelle heure pour tel évènement
    @cmd = "Building_objectives"    if @what == "policy"
  end



  def delete(events)
    events.each_index { |i|
      event = JSON.parse(events[i])
      if event["id"] == @id
        events.delete_at(i)
        return events
      end
    }
  end

  def belongs_to(events)
    events.each { |event|
      return true if JSON.parse(event)["id"] == @id
    }
    false
  end


  def to_json(*a)
    {
        'label' => @label,
        'id' => @id,
        'what' => @what,
        'periodicity' => @periodicity
    }.to_json(*a)
  end

  def execute(load_server_port)
    begin
      s = TCPSocket.new "localhost", load_server_port
      s.puts JSON.generate({"cmd" => @cmd,
                            "label" => @label,
                            "date_building" => Date.today})
      s.close
      p "send to load_server #{@label} "
      Logging.send(@@log_file, Logger::DEBUG, "send to load_server #{self.to_json}")

    rescue Exception => e
      p "failed to send to load_server #{@label} "
      Logging.send(@@log_file, Logger::ERROR, "failed to send to load_server #{self.to_json}")

    end
  end

end

