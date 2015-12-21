require 'eventmachine'


class Question
  class Connection < EventMachine::Connection
    include EM::P::ObjectProtocol
    attr_reader :data, :q

    def initialize(data, q)
      @data = data
      @q = q

    end

    def post_init
      send_object @data
    end

    def receive_object data
      #EventMachine.stop
      @data = data
      p @data
      @q << @data
    end

  end

  attr :data, :q, :rep

  def initialize(data)
    @data = data
    @q = EM::Queue.new

  end

  def ask_to(hostname = "localhost", port)


    EventMachine.connect hostname, port, Connection, @data, @q

    begin
      r = @q.pop(true)

    rescue Exception => e
      p e.message
      sleep 5
      retry
    else
      p r
    end
    r
  end
end
#
# q = Queue.new
# EventMachine.run {
#
#   p "=>#{Question.new({:eric => 1}).ask_to("localhost", 9999)}"
#
# }

def serializer
  Marshal
end

# Sends a ruby object over the network
def send_object obj
  data = serializer.dump(obj)
  send_data [data.respond_to?(:bytesize) ? data.bytesize : data.size, data].pack('Na*')
end


send_object({:eric => 1})