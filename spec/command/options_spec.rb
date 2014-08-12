# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe Command::Options do
    before do
      @subject = Command::Options
      @subject.instance_variable_set(:@fixture_output, '')
      def @subject.puts(text)
        @fixture_output << "#{text}\n"
      end
    end

    describe '::default_options' do
      it 'returns the default options for root commands' do
        @subject.default_options(Fixture::Command).flatten.should.
          include?('--version')
        @subject.default_options(Fixture::Command).flatten.should.
          include?('--verbose')
      end

      it 'returns the default options for non-root commands' do
        @subject.default_options(Fixture::Command::SpecFile).flatten.should.
          not.include?('--version')
        @subject.default_options(Fixture::Command::SpecFile).flatten.should.
          include?('--verbose')
      end
    end

    describe '::handle_root_option' do
      it 'handles the version flag' do
        @subject.expects(:print_version)
        argv = %w(--version)
        command = Fixture::Command.new(argv)
        @subject.handle_root_option(command, argv).should.be.true
      end

      it 'does not handle the version flag for non root commands' do
        @subject.expects(:print_version).never
        argv = %w(--version)
        command = Fixture::Command::SpecFile.new(argv)
        @subject.handle_root_option(command, argv).should.be.false
      end

      it 'handles the completion-script flag' do
        @subject.expects(:print_completion_template)
        argv = %w(--completion-script)
        command = Fixture::Command.new(argv)
        @subject.handle_root_option(command, argv).should.be.true
      end

      it 'does not handle the completion-script flag for non root commands' do
        @subject.expects(:print_version).never
        argv = %w(--completion-script)
        command = Fixture::Command::SpecFile.new(argv)
        @subject.handle_root_option(command, argv).should.be.false
      end
    end

    describe '::print_version' do
      it 'prints the version' do
        command = Fixture::Command.new(%w(--version))
        command.class.version = '1.0'

        @subject.instance_variable_set(:@fixture_output, '')
        def @subject.puts(text)
          @fixture_output << text
        end

        @subject.print_version(command)
        output = @subject.instance_variable_get(:@fixture_output)
        output.should == '1.0'
      end

      it 'includes plugins version if the verbose flag has been specified' do
        spec = stub(:name => 'cocoapods_plugin', :version => '1.0')
        Command::PluginsHelper.expects(:specifications).returns([spec])

        command = Fixture::Command.new(%w(--version --verbose))
        command.class.version = '1.0'
        @subject.print_version(command)
        output = @subject.instance_variable_get(:@fixture_output)
        output.should == "1.0\ncocoapods_plugin: 1.0\n"
      end
    end

    describe '::print_completion_template' do
      it 'handles the completion-script flag' do
        command = Fixture::Command.new(%w(--completion-script))
        Command::ShellCompletionHelper.expects(:completion_template).
          with(command.class).returns('template')
        @subject.print_completion_template(command)
        output = @subject.instance_variable_get(:@fixture_output)
        output.should == "template\n"
      end
    end
  end
end
