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

  def spec_args(conf, adapter)
    Rails.version < '5' ? [conf, adapter] : ['dummy', conf, adapter]
  end

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
    spec = ConnectionSpecification.new(*spec_args(conf, 'adapter'))
    expect(spec.config[:username]).to eq('canvas')
    expect(spec.config[:database]).to eq('master')
    Shackles.activate(:deploy) do
      expect(spec.config[:username]).to eq('deploy')
      expect(spec.config[:database]).to eq('master')
    end
    expect(spec.config[:username]).to eq('canvas')
    expect(spec.config[:database]).to eq('master')
    Shackles.activate(:slave) do
      expect(spec.config[:username]).to eq('canvas')
      expect(spec.config[:database]).to eq('slave')
    end
    expect(spec.config[:username]).to eq('canvas')
    expect(spec.config[:database]).to eq('master')
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
    spec = ConnectionSpecification.new(*spec_args(conf, 'adapter'))
    expect(spec.config[:username]).to eq('canvas')
    Shackles.activate(:deploy) do
      expect(spec.config[:username]).to eq('deploy')
    end
    expect(spec.config[:username]).to eq('canvas')
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
    spec = ConnectionSpecification.new(*spec_args(conf.dup, 'adapter'))
    expect(spec.config[:username]).to eq('canvas')
    spec.config[:schema_search_path] = 'bob'
    expect(spec.config[:schema_search_path]).to eq('bob')
    expect(spec.config[:username]).to eq('bob')
    Shackles.activate(:deploy) do
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
        :database => 'master',
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
      expect(conn).not_to eq(slave_conn)
      expect(ActiveRecord::Base.connection).to eq(conn)
    end

    it "should track all activated environments" do
      Shackles.activate(:slave) {}
      Shackles.activate(:custom) {}
      expected = Set.new([:master, :slave, :custom])
      expect(Shackles.activated_environments & expected).to eq(expected)
    end

    context "non-transactional" do
      it "should really disconnect all envs" do
        ActiveRecord::Base.connection
        expect(ActiveRecord::Base.connection_pool).to be_connected

        Shackles.activate(:slave) do
          ActiveRecord::Base.connection
          expect(ActiveRecord::Base.connection_pool).to be_connected
        end

        ActiveRecord::Base.clear_all_connections!
        expect(ActiveRecord::Base.connection_pool).not_to be_connected
        Shackles.activate(:slave) do
          expect(ActiveRecord::Base.connection_pool).not_to be_connected
        end
      end
    end

    it 'is thread safe' do
      Shackles.activate(:slave) do
        Thread.new do
          Shackles.activate!(:deploy)
          expect(Shackles.environment).to eq :deploy
        end.join
        expect(Shackles.environment).to eq :slave
      end
    end
  end
end
