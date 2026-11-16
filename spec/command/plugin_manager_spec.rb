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

    after do
      @manager.instance_variable_set(:@loaded_plugins, nil)
    end

    describe '::load_plugins' do
      it 'requires the plugins paths' do
        @manager.expects(:safe_require).with([@path.to_s])
        @manager.load_plugins('fixture')
      end

      it 'stores the plugins paths per plugin prefix' do
        @manager.load_plugins('fixture')
        expect(@manager.loaded_plugins).to eq(
          'fixture' => [@spec],
        )
      end

      it 'requires the plugins only if they have not been already loaded' do
        @manager.expects(:safe_require).
          with([@path.to_s]).once
        @manager.load_plugins('fixture')
        @manager.load_plugins('fixture')
      end
    end

    describe '::specifications' do
      it 'returns the list of the specifications' do
        @manager.load_plugins('fixture')
        expect(@manager.specifications).to eq([@spec])
      end
    end

    describe '::installed_specifications_for_prefix' do
      it 'returns the list of specifications when the prefix has been loaded' do
        @manager.load_plugins('fixture')
        @manager.expects(:plugin_gems_for_prefix).never
        expect(@manager.installed_specifications_for_prefix('fixture')).
          to eq([@spec])
      end

      it 'returns the lists of specifications when the prefix has not been ' \
         'loaded' do
        expect(@manager.installed_specifications_for_prefix('fixture')).
          to eq([@spec])
      end
    end

    describe '::plugins_involved_in_exception' do
      it 'returns the list of the plugins involved in an exception' do
        backtrace = [(@path + '../command.rb').to_s]
        exception = stub(:backtrace => backtrace)
        @manager.load_plugins('fixture')
        expected = [
          @spec.name,
        ]
        expect(@manager.plugins_involved_in_exception(exception)).
          to eq(expected)
      end
    end

    describe '::safe_require' do
      it 'requires a path catching any exception' do
        @manager.unstub(:require)
        path = ROOT + 'spec/fixture/command/load_error_fixture_plugin.rb'

        def @manager.warn(text)
          (@fixture_output ||= '') << text
        end

        expect do
          @manager.safe_require([path.to_s])
        end.not_to raise_error

        output = @manager.instance_variable_get(:@fixture_output)
        expect(output).to include('Error loading plugin file')
        expect(output).to include('LoadError')
      end
    end
  end
end
