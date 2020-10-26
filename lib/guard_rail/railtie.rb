# frozen_string_literal: true

module GuardRail
  class Railtie < Rails::Railtie
    initializer "guard_rail.extend_ar", :before => "active_record.initialize_database" do
      ActiveSupport.on_load(:active_record) do
        GuardRail.initialize!
      end
    end
  end
end
