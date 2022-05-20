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
      # Don't reset the shard when changing the role
      ActiveRecord::Base.connecting_to(role: role, shard: nil)
    end
  end
end
