# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe Command::PluginsHelper do
    before do
      @subject = Command::PluginsHelper
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

    describe '::plugin_info' do
      it 'returns the information for a given plugin' do
        path = 'path/to/gems/cocoapods-plugins/lib/cocoapods_plugin.rb'
        gemspec = 'path/to/gems/cocoapods-plugins/cocoapods-plugins.gemspec'
        spec = stub(:name => 'cocoapods-plugins', :version => '0.1.0')
        @subject.stubs(:find_gemspec).returns(gemspec)
        Gem::Specification.expects(:load).with(gemspec).returns(spec)
        @subject.plugin_info(path).should == 'cocoapods-plugins: 0.1.0'
      end

      it 'returns an error message if the specification could not be loaded' do
        path = 'path/to/gems/cocoapods-plugins/lib/cocoapods_plugin.rb'
        @subject.stubs(:find_gemspec).returns(nil)
        result = @subject.plugin_info(path)
        result.should.include('[!] Unable to load a specification for ')
        result.should.include('path/to/gems/cocoapods-plugins')
      end
    end

    describe '::find_gemspec' do
      it 'returns the path of the gemspec of a path' do
        path = 'path/to/gems/cocoapods-plugins/lib/cocoapods_plugin.rb'
        gemspec_glob = 'path/to/gems/cocoapods-plugins/*.gemspec'
        gemspec = 'path/to/gems/cocoapods-plugins/cocoapods-plugins.gemspec'
        Dir.stubs(:glob).returns([])
        Dir.expects(:glob).with(gemspec_glob).returns([gemspec])
        @subject.find_gemspec(path).should == gemspec
      end
    end

    describe '::reverse_ascending_paths' do
      it 'returns the parent paths of a path' do
        @subject.reverse_ascending_paths('dir_1/dir_2/file').should ==
        %w( dir_1/dir_2 dir_1 )
      end
    end

    describe '::safe_require' do
      it 'requires a path catching any exception' do
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
