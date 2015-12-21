module Tasking
  module Visit

    class Page

      attr :delay

      def initialize(delay)
        @delay = delay
      end

      def duration
        @delay.to_i
      end
    end

  end
end