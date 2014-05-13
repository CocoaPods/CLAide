# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe Command::PluginsHelper do
    before do
      @subject = Command::PluginsHelper
      @subject.instance_variable_set(:@plugin_paths, nil)
      @subject.stubs(:require)
      @path = ROOT + 'spec/fixture/command/plugin_fixture.rb'
      Gem.stubs(:find_latest_files).returns([@path])
    end

    describe '::load_plugins' do
      it 'requires the plugins paths' do
        @subject.expects(:safe_require).with(@path.to_s)
        @subject.load_plugins('fixture')
      end

      it 'requires the plugins paths' do
        @subject.load_plugins('fixture')
        @subject.plugin_paths.should == [
          ROOT + 'spec/fixture'
        ]
      end

      it 'requires the plugins only if they have not been already loaded' do
        @subject.expects(:safe_require).with(@path.to_s).once
        @subject.load_plugins('fixture')
        @subject.load_plugins('fixture')
      end
    end

    describe '::specifications' do
      it 'returns the list of the specifications' do
        spec = stub
        @subject.load_plugins('fixture')
        @subject.expects(:specification).with(@path + '../../').returns(spec)
        @subject.specifications.should == [spec]
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
        @subject.specification(root).should == spec
      end

      it 'warns if unable to load a specification' do
        root = @path + '../../'
        message = '[!] Unable to load a specification for the plugin ' \
          "`#{root}`"
        Dir.expects(:glob).returns([])
        @subject.expects(:warn).with(message)
        @subject.specification(root).should.nil?
      end
    end

    describe '::plugins_involved_in_exception' do
      it 'returns the list of the plugins involved in an exception' do
        backtrace = [(@path + '../command.rb').to_s]
        exception = stub(:backtrace => backtrace)
        @subject.load_plugins('fixture')
        @subject.plugins_involved_in_exception(exception).should == [
          'fixture'
        ]
      end
    end

    describe '::plugin_load_paths' do
      it 'returns the load paths of the plugins' do
        Gem.expects(:respond_to?).returns(true)
        paths = ['path/to/gems/cocoapods-plugins/lib/cocoapods_plugin.rb']
        Gem.expects(:find_latest_files).with('cocoapods_plugin').returns(paths)
        @subject.plugin_load_paths('cocoapods').should == paths
      end

      it 'returns an empty array if no plugin prefix is given' do
        @subject.plugin_load_paths(nil).should == []
        @subject.plugin_load_paths('').should == []
      end

      it 'is compatible with older versions of Ruby Gems' do
        Gem.expects(:respond_to?).returns(false)
        paths = ['path/to/gems/cocoapods-plugins/lib/cocoapods_plugin.rb']
        Gem.expects(:find_files).with('cocoapods_plugin').returns(paths)
        @subject.plugin_load_paths('cocoapods').should == paths
      end
    end

    describe '::safe_require' do
      it 'requires a path catching any exception' do
        @subject.unstub(:require)
        path = ROOT + 'spec/fixture/command/load_error_plugin_fixture.rb'

        def @subject.puts(text)
          (@fixture_output ||= '') << text
        end

        should.not.raise do
          @subject.safe_require(path)
        end

        output = @subject.instance_variable_get(:@fixture_output)
        output.should.include('Error loading the plugin')
        output.should.include('LoadError')
      end
    end
  end
end
