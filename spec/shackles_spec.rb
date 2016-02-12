require 'active_record'
require 'byebug'
require 'rails'
require 'shackles'

# we're not actually bringing up ActiveRecord, so we need to initialize our stuff
Shackles.initialize!

RSpec.configure do |config|
  config.mock_framework = :mocha
end

describe Shackles do
  ConnectionSpecification = ActiveRecord::ConnectionAdapters::ConnectionSpecification

  it "should allow changing environments" do
    conf = {
        :adapter => 'postgresql',
        :database => 'master',
        :username => 'canvas',
        :deploy => {
            :username => 'deploy'
        },
        :slave => {
            :database => 'slave'
        }
    }
    spec = ConnectionSpecification.new(conf, 'adapter')
    spec.config[:username].should == 'canvas'
    spec.config[:database].should == 'master'
    Shackles.activate(:deploy) do
      spec.config[:username].should == 'deploy'
      spec.config[:database].should == 'master'
    end
    spec.config[:username].should == 'canvas'
    spec.config[:database].should == 'master'
    Shackles.activate(:slave) do
      spec.config[:username].should == 'canvas'
      spec.config[:database].should == 'slave'
    end
    spec.config[:username].should == 'canvas'
    spec.config[:database].should == 'master'
  end

  it "should allow using hash insertions" do
    conf = {
        :adapter => 'postgresql',
        :database => 'master',
        :username => '%{schema_search_path}',
        :schema_search_path => 'canvas',
        :deploy => {
            :username => 'deploy'
        }
    }
    spec = ConnectionSpecification.new(conf, 'adapter')
    spec.config[:username].should == 'canvas'
    Shackles.activate(:deploy) do
      spec.config[:username].should == 'deploy'
    end
    spec.config[:username].should == 'canvas'
  end

  it "should be cache coherent with modifying the config" do
    conf = {
        :adapter => 'postgresql',
        :database => 'master',
        :username => '%{schema_search_path}',
        :schema_search_path => 'canvas',
        :deploy => {
            :username => 'deploy'
        }
    }
    spec = ConnectionSpecification.new(conf.dup, 'adapter')
    spec.config[:username].should == 'canvas'
    spec.config[:schema_search_path] = 'bob'
    spec.config[:schema_search_path].should == 'bob'
    spec.config[:username].should == 'bob'
    Shackles.activate(:deploy) do
      spec.config[:schema_search_path].should == 'bob'
      spec.config[:username].should == 'deploy'
    end
    external_config = spec.config.dup
    external_config.class.should == Hash
    external_config.should == spec.config

    spec.config = conf.dup
    spec.config[:username].should == 'canvas'
  end

  describe "activate" do
    before do
      #!!! trick it in to actually switching envs
      Rails.env.stubs(:test?).returns(false)

      # be sure to test bugs where the current env isn't yet included in this hash
      Shackles.connection_handlers.clear

      ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
    end

    it "should call ensure_handler when switching envs" do
      old_handler = ActiveRecord::Base.connection_handler
      Shackles.expects(:ensure_handler).returns(old_handler).twice
      Shackles.activate(:slave) {}
    end

    it "should not close connections when switching envs" do
      conn = ActiveRecord::Base.connection
      slave_conn = Shackles.activate(:slave) { ActiveRecord::Base.connection }
      conn.should_not == slave_conn
      ActiveRecord::Base.connection.should == conn
    end

    it "should track all activated environments" do
      Shackles.activate(:slave) {}
      Shackles.activate(:custom) {}
      expected = Set.new([:master, :slave, :custom])
      (Shackles.activated_environments & expected).should == expected
    end

    context "non-transactional" do
      it "should really disconnect all envs" do
        ActiveRecord::Base.connection
        ActiveRecord::Base.connection_pool.should be_connected

        Shackles.activate(:slave) do
          ActiveRecord::Base.connection
          ActiveRecord::Base.connection_pool.should be_connected
        end

        ActiveRecord::Base.clear_all_connections!
        ActiveRecord::Base.connection_pool.should_not be_connected
        Shackles.activate(:slave) do
          ActiveRecord::Base.connection_pool.should_not be_connected
        end
      end
    end
  end
end
