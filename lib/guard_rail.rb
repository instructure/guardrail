# frozen_string_literal: true

module GuardRail
  class << self
    def environment
      ActiveRecord::Base.current_role
    end

    def activate(role)
      return yield if environment == role
      ActiveRecord::Base.connected_to(role: role) { yield }
    end

    def activate!(role)
      return if environment == role
      ActiveRecord::Base.connecting_to(role: role)
    end
  end
end
