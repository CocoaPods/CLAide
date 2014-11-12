# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe Command::PluginManager do
    before do
      @manager = Command::PluginManager
      @manager.instance_variable_set(:@plugin_paths, nil)
      @manager.stubs(:require)
      @path = ROOT + 'spec/fixture/command/plugin_fixture.rb'
      Gem.stubs(:find_latest_files).returns([@path])
    end

    describe '::load_plugins' do
      it 'requires the plugins paths' do
        @manager.expects(:safe_require).with(@path.to_s)
        @manager.load_plugins('fixture')
      end

      it 'stores the plugins paths per plugin prefix' do
        @manager.load_plugins('fixture')
        @manager.plugin_paths.should == {
          'fixture' => [ROOT + 'spec/fixture'],
        }
      end

      it 'requires the plugins only if they have not been already loaded' do
        @manager.expects(:safe_require).with(@path.to_s).once
        @manager.load_plugins('fixture')
        @manager.load_plugins('fixture')
      end
    end

    describe '::specifications' do
      it 'returns the list of the specifications' do
        spec = stub
        @manager.load_plugins('fixture')
        @manager.expects(:specification).with(@path + '../../').returns(spec)
        @manager.specifications.should == [spec]
      end
    end

    describe '::specification' do
      it 'returns the list of the specifications' do
        root = @path + '../../'
        gemspec_glob = "#{root}/*.gemspec"
        gemspec_path = @path + '../../fixtures.gemspec'
        spec = stub
        Dir.expects(:glob).with(gemspec_glob).returns([gemspec_path])
        Gem::Specification.expects(:load).with(gemspec_path).returns(spec)
        @manager.specification(root).should == spec
      end

      it 'warns if unable to load a specification' do
        root = @path + '../../'
        message = '[!] Unable to load a specification for the plugin ' \
          "`#{root}`"
        Dir.expects(:glob).returns([])
        @manager.expects(:warn).with(message)
        @manager.specification(root).should.nil?
      end
    end

    describe '::plugins_involved_in_exception' do
      it 'returns the list of the plugins involved in an exception' do
        backtrace = [(@path + '../command.rb').to_s]
        exception = stub(:backtrace => backtrace)
        @manager.load_plugins('fixture')
        @manager.plugins_involved_in_exception(exception).should == [
          'fixture',
        ]
      end
    end

    describe '::plugin_load_paths' do
      it 'returns the load paths of the plugins' do
        Gem.expects(:respond_to?).returns(true)
        paths = ['path/to/gems/cocoapods-plugins/lib/cocoapods_plugin.rb']
        Gem.expects(:find_latest_files).with('cocoapods_plugin').returns(paths)
        @manager.plugin_load_paths('cocoapods').should == paths
      end

      it 'returns an empty array if no plugin prefix is given' do
        @manager.plugin_load_paths(nil).should == []
        @manager.plugin_load_paths('').should == []
      end

      it 'is compatible with older versions of Ruby Gems' do
        Gem.expects(:respond_to?).returns(false)
        paths = ['path/to/gems/cocoapods-plugins/lib/cocoapods_plugin.rb']
        Gem.expects(:find_files).with('cocoapods_plugin').returns(paths)
        @manager.plugin_load_paths('cocoapods').should == paths
      end
    end

    describe '::safe_require' do
      it 'requires a path catching any exception' do
        @manager.unstub(:require)
        path = ROOT + 'spec/fixture/command/load_error_plugin_fixture.rb'

        def @manager.puts(text)
          (@fixture_output ||= '') << text
        end

        should.not.raise do
          @manager.safe_require(path)
        end

        output = @manager.instance_variable_get(:@fixture_output)
        output.should.include('Error loading the plugin')
        output.should.include('LoadError')
      end
    end
  end
end
