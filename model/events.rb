
require File.dirname(__FILE__) + '/../model/event.rb'
class Events
  # To change this template use File | Settings | File Templates.

  EVENTS_FILE = File.dirname(__FILE__) + "/../data/" + File.basename(__FILE__, ".rb") + ".json"
  attr :events,
       :load_server_port

  def initialize(load_server_port)
    @load_server_port = load_server_port
    @events = Array.new
    begin
      JSON.parse(File.read(EVENTS_FILE)).each { |evt|
        @events << Event.new(evt["key"], evt["cmd"], evt["periodicity"], evt["business"])
      }
      p @events
    rescue Exception => e

    end
  end

  def save()
    events_file = File.open(EVENTS_FILE, "w")
    events_file.sync = true
    events_file.write(JSON.pretty_generate(@events))
    events_file.close
  end

  def exist?(event)
    @events.each { |evt|
      return true if evt.key == event.key and evt.cmd == event.cmd
    } unless @events.nil?
    false
  end

  def add(event)
    event.each { |evt| @events << evt } if event.is_a?(Array)
    @events << event unless event.is_a?(Array)
  end

  def delete(event)
    @events.each_index { |i|
      @events.delete_at(i) if @events[i].key == event.key and @events[i].cmd == event.cmd
    }
  end

  def execute_one(event)
    @events.each { |evt|
      evt.execute(@load_server_port) if evt.key == event.key and evt.cmd == event.cmd
    } unless @events.nil?
  end

  def execute_all_at_time(time=Date.today)
    #TODO controler l'execution de execute all at time
    @events.each { |evt|
      schedule =IceCube::Schedule.from_yaml(evt.periodicity)
      p schedule
      evt.execute(@load_server_port) if schedule.occurs_on?(time)
    }
  end
end



