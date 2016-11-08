require_relative 'traffic'
require_relative '../../../lib/parameter'

module Planning

  class Advert < Traffic

    def initialize(data)
      super(data)
      # policy data
      @policy_type = "advert"

    end

  end


end