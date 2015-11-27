# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe Command::PluginManager do
    before do
      extend SpecHelper::RubyGems
      @manager = Command::PluginManager
      @manager.instance_variable_set(:@loaded_plugins, nil)
      @manager.stubs(:require)
      @path = ROOT + 'spec/fixture/command/fixture_plugin.rb'
      @spec = fixture_spec_with_file(@path)
      stub_latest_specs(@spec)
    end

    describe '::load_plugins' do
      it 'requires the plugins paths' do
        @manager.expects(:safe_activate_and_require).with(@spec, [@path.to_s])
        @manager.load_plugins('fixture')
      end

      it 'stores the plugins paths per plugin prefix' do
        @manager.load_plugins('fixture')
        @manager.loaded_plugins.should == {
          'fixture' => [@spec],
        }
      end

      it 'requires the plugins only if they have not been already loaded' do
        @manager.expects(:safe_activate_and_require).
          with(@spec, [@path.to_s]).once
        @manager.load_plugins('fixture')
        @manager.load_plugins('fixture')
      end
    end

    describe '::specifications' do
      it 'returns the list of the specifications' do
        @manager.load_plugins('fixture')
        @manager.specifications.should == [@spec]
      end
    end

    describe '::plugins_involved_in_exception' do
      it 'returns the list of the plugins involved in an exception' do
        backtrace = [(@path + '../command.rb').to_s]
        exception = stub(:backtrace => backtrace)
        @manager.load_plugins('fixture')
        @manager.plugins_involved_in_exception(exception).should == [
          @spec.name,
        ]
      end
    end

    describe '::safe_activate_and_require' do
      it 'requires a path catching any exception' do
        @manager.unstub(:require)
        path = ROOT + 'spec/fixture/command/load_error_fixture_plugin.rb'

        def @manager.warn(text)
          (@fixture_output ||= '') << text
        end

        should.not.raise do
          @manager.safe_activate_and_require(@spec, [path.to_path])
        end

        output = @manager.instance_variable_get(:@fixture_output)
        output.should.include('Error loading the plugin')
        output.should.include('LoadError')
      end
    end
  end
end
