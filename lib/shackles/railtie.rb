module Shackles
  class Railtie < Rails::Railtie
    initializer "shackles.extend_ar", :before => "active_record.initialize_database" do
      ActiveSupport.on_load(:active_record) do
        Shackles.initialize!
      end
    end
  end
end
