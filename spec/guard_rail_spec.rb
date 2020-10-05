require 'active_record'
require 'byebug'
require 'rails'
require 'guard_rail'

# we're not actually bringing up ActiveRecord, so we need to initialize our stuff
GuardRail.initialize!

RSpec.configure do |config|
  config.mock_framework = :mocha
end

describe GuardRail do
  ConnectionSpecification = ActiveRecord::ConnectionAdapters::ConnectionSpecification

  def spec_args(conf, adapter)
    ['dummy', conf, adapter]
  end

  it "should allow changing environments" do
    conf = {
        :adapter => 'postgresql',
        :database => 'primary',
        :username => 'canvas',
        :deploy => {
            :username => 'deploy'
        },
        :replica => {
            :database => 'replica'
        }
    }
    spec = ConnectionSpecification.new(*spec_args(conf, 'adapter'))
    expect(spec.config[:username]).to eq('canvas')
    expect(spec.config[:database]).to eq('primary')
    GuardRail.activate(:deploy) do
      expect(spec.config[:username]).to eq('deploy')
      expect(spec.config[:database]).to eq('primary')
    end
    expect(spec.config[:username]).to eq('canvas')
    expect(spec.config[:database]).to eq('primary')
    GuardRail.activate(:replica) do
      expect(spec.config[:username]).to eq('canvas')
      expect(spec.config[:database]).to eq('replica')
    end
    expect(spec.config[:username]).to eq('canvas')
    expect(spec.config[:database]).to eq('primary')
  end

  it "should allow using hash insertions" do
    conf = {
        :adapter => 'postgresql',
        :database => 'primary',
        :username => '%{schema_search_path}',
        :schema_search_path => 'canvas',
        :deploy => {
            :username => 'deploy'
        }
    }
    spec = ConnectionSpecification.new(*spec_args(conf, 'adapter'))
    expect(spec.config[:username]).to eq('canvas')
    GuardRail.activate(:deploy) do
      expect(spec.config[:username]).to eq('deploy')
    end
    expect(spec.config[:username]).to eq('canvas')
  end

  it "should be cache coherent with modifying the config" do
    conf = {
        :adapter => 'postgresql',
        :database => 'primary',
        :username => '%{schema_search_path}',
        :schema_search_path => 'canvas',
        :deploy => {
            :username => 'deploy'
        }
    }
    spec = ConnectionSpecification.new(*spec_args(conf.dup, 'adapter'))
    expect(spec.config[:username]).to eq('canvas')
    spec.config[:schema_search_path] = 'bob'
    expect(spec.config[:schema_search_path]).to eq('bob')
    expect(spec.config[:username]).to eq('bob')
    GuardRail.activate(:deploy) do
      expect(spec.config[:schema_search_path]).to eq('bob')
      expect(spec.config[:username]).to eq('deploy')
    end
    external_config = spec.config.dup
    expect(external_config.class).to eq(Hash)
    expect(external_config).to eq(spec.config)

    spec.config = conf.dup
    expect(spec.config[:username]).to eq('canvas')
  end

  it "does not share config objects when dup'ing specs" do
    conf = {
        :adapter => 'postgresql',
        :database => 'primary',
        :username => '%{schema_search_path}',
        :schema_search_path => 'canvas',
        :deploy => {
            :username => 'deploy'
        }
    }
    spec = ConnectionSpecification.new(*spec_args(conf.dup, 'adapter'))
    expect(spec.config.object_id).not_to eq spec.dup.config.object_id
  end

  describe "activate" do
    before do
      #!!! trick it in to actually switching envs
      Rails.env.stubs(:test?).returns(false)

      # be sure to test bugs where the current env isn't yet included in this hash
      GuardRail.connection_handlers.clear

      ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
    end

    it "should call ensure_handler when switching envs" do
      old_handler = ActiveRecord::Base.connection_handler
      GuardRail.expects(:ensure_handler).returns(old_handler).twice
      GuardRail.activate(:replica) {}
    end

    it "should not close connections when switching envs" do
      conn = ActiveRecord::Base.connection
      replica_conn = GuardRail.activate(:replica) { ActiveRecord::Base.connection }
      expect(conn).not_to eq(replica_conn)
      expect(ActiveRecord::Base.connection).to eq(conn)
    end

    it "should track all activated environments" do
      GuardRail.activate(:replica) {}
      GuardRail.activate(:custom) {}
      expected = Set.new([:primary, :replica, :custom])
      expect(GuardRail.activated_environments & expected).to eq(expected)
    end

    context "non-transactional" do
      it "should really disconnect all envs" do
        ActiveRecord::Base.connection
        expect(ActiveRecord::Base.connection_pool).to be_connected

        GuardRail.activate(:replica) do
          ActiveRecord::Base.connection
          expect(ActiveRecord::Base.connection_pool).to be_connected
        end

        ActiveRecord::Base.clear_all_connections!
        expect(ActiveRecord::Base.connection_pool).not_to be_connected
        GuardRail.activate(:replica) do
          expect(ActiveRecord::Base.connection_pool).not_to be_connected
        end
      end
    end

    it 'is thread safe' do
      GuardRail.activate(:replica) do
        Thread.new do
          GuardRail.activate!(:deploy)
          expect(GuardRail.environment).to eq :deploy
        end.join
        expect(GuardRail.environment).to eq :replica
      end
    end
  end
end
