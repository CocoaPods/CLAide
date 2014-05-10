# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

module CLAide
  describe Command do

    before do
      @subject = Fixture::Command
    end

    describe 'in general' do
      it 'registers the subcommand classes' do
        @subject.subcommands.map(&:command).should ==
          %w(spec-file)
        @subject::SpecFile.subcommands.map(&:command).should ==
          %w(common-invisible-command)
        @subject::SpecFile::Create.subcommands.map(&:command).should ==
          []
        @subject::SpecFile::Lint.subcommands.map(&:command).should ==
          %w(repo)
      end

      it 'returns subcommands for look up' do
        subcommands = @subject::SpecFile.subcommands_for_command_lookup
        subcommands.map(&:command).should == %w(lint create)
      end

      it 'returns whether it is the root command' do
        @subject.should.be.root_command?
        @subject::SpecFile.should.not.be.root_command?
      end

      it 'tries to match a subclass for each of the subcommands' do
        parsed = @subject.parse(%w(spec-file --verbose lint))
        parsed.should.be.instance_of @subject::SpecFile::Lint
      end
    end

    #-------------------------------------------------------------------------#

    describe 'class methods' do
      it 'returns that ANSI output should be used if a TTY is present' do
        @subject.ansi_output = nil
        STDOUT.expects(:tty?).returns(true)
        @subject.ansi_output.should.be.true
      end

      it 'returns that ANSI output should be used if a TTY is not present' do
        @subject.ansi_output = nil
        STDOUT.expects(:tty?).returns(false)
        @subject.ansi_output.should.be.false
      end
    end

    #-------------------------------------------------------------------------#

    describe 'plugins' do
      describe 'when the plugin is at <command-prefix>_plugin.rb' do
        before do
          path = ROOT + 'spec/fixture/command/plugin_fixture.rb'
          Gem.stubs(:find_latest_files).returns([path])
        end

        it 'loads the plugin' do
          Fixture::CommandPluginable.subcommands.find do |cmd|
            cmd.command == 'demo-plugin'
          end.should.be.nil

          Fixture::CommandPluginable.load_plugins
          plugin_command = Fixture::CommandPluginable.subcommands.find do |cmd|
            cmd.command == 'demo-plugin'
          end
          plugin_command.should.not.be.nil
          plugin_command.ancestors.should.include Fixture::CommandPluginable
          plugin_command.description.should =~ /plugins/
        end

        it 'is available for help' do
          Fixture::CommandPluginable.load_plugins
          banner = CLAide::Command::Banner.new(Fixture::CommandPluginable)
          banner.formatted_banner.should =~ /demo-plugin/
        end
      end

      describe 'failing plugins' do
        it 'rescues exceptions raised during the load of the plugin' do
          path = ROOT + 'spec/fixture/command/load_error_plugin_fixture.rb'
          should.raise LoadError do
            require path
          end

          Gem.stubs(:find_latest_files).returns([path])
          should.not.raise do
            @subject.load_plugins
          end
        end
      end

      it 'fails normally if there is no plugin' do
        @subject.load_plugins
        @subject.subcommands.find do
          |cmd| cmd.name == 'demo-plugin'
        end.should.be.nil
      end
    end

    #-------------------------------------------------------------------------#

    describe 'validation' do
      it 'does not raise if one of the subcommands consumes arguments' do
        subcommand = @subject.parse(%w(spec-file create AFNetworking))
        subcommand.spec.should == 'AFNetworking'
      end

      it 'raises a Help exception when created with an invalid subcommand' do
        message = "Unknown command: `unknown`\nDid you mean: spec-file"
        should_raise_help message do
          @subject.parse(%w(unknown)).validate!
        end

        should_raise_help "Unknown command: `unknown`\nDid you mean: lint" do
          @subject.parse(%w(spec-file unknown)).validate!
        end
      end

      it 'raises an empty Help exception when called on an abstract command' do
        should_raise_help nil do
          @subject.parse(%w(spec-file)).validate!
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe 'default options' do
      it 'raises a Help exception, without error message' do
        should_raise_help nil do
          @subject.parse(%w(--help)).validate!
        end
      end

      it 'sets the verbose flag' do
        command = @subject.parse([])
        command.should.not.be.verbose
        command = @subject.parse(%w(--verbose))
        command.should.be.verbose
      end

      it 'handles the version flag' do
        command = @subject
        command.version = '1.0'
        command.instance_variable_set(:@fixture_output, '')
        def command.puts(text)
          @fixture_output << text
        end
        command.run(%w(--version))
        output = command.instance_variable_get(:@fixture_output)
        output.should == '1.0'
      end

      it 'handles the version flag in conjunction with the verbose flag' do
        path = 'path/to/gems/cocoapods-plugins/lib/cocoapods_plugin.rb'
        Command::PluginsHelper.expects(:plugin_load_paths).returns([path])
        Command::PluginsHelper.expects(:plugin_info).
          returns('cocoapods_plugin: 1.0')
        command = @subject
        command.stubs(:load_plugins)
        command.version = '1.0'
        command.instance_variable_set(:@fixture_output, '')
        def command.puts(text)
          @fixture_output << "#{text}\n"
        end
        command.run(%w(--version --verbose))
        output = command.instance_variable_get(:@fixture_output)
        output.should == "1.0\ncocoapods_plugin: 1.0\n"
      end

      it "doesn't include the version flag for non root commands" do
        @subject.expects(:exit).with(1)
        @subject.run((%w(spec-file --version)))
      end

      it 'handles the completion-script flag' do
        command = @subject
        command.instance_variable_set(:@fixture_output, '')
        def command.puts(text)
          @fixture_output << text
        end
        Command::ShellCompletionHelper.
          expects(:completion_template).returns('script')
        command.run(%w(--completion-script))
        output = command.instance_variable_get(:@fixture_output)
        output.should == 'script'
      end

      it "doesn't include the completion-script flag for non root commands" do
        @subject.expects(:exit).with(1)
        @subject.run((%w(spec-file --completion-script)))
      end
    end

    #-------------------------------------------------------------------------#

    describe 'when running' do
      before do
        @subject.stubs(:puts)
        @subject.stubs(:exit)
      end

      it 'invokes an instance of the parsed subcommand' do
        @subject::SpecFile.any_instance.stubs(:validate!)
        @subject::SpecFile.any_instance.expects(:run)
        @subject.run(%w(spec-file))
      end

      it 'does not print the backtrace of an InformativeError by default' do
        ::CLAide::ANSI.disabled = true
        expected = Help.new(@subject.banner).message
        @subject.expects(:puts).with(expected)
        @subject.run(%w(--help))
      end

      it 'prints the backtrace of an InformativeError, if set to verbose' do
        error = Fixture::Error.new
        @subject.any_instance.stubs(:validate!).raises(error)
        error.stubs(:message).returns('the message')
        error.stubs(:backtrace).returns(%w(the backtrace))

        printed = states('printed').starts_as(:nothing)
        @subject.expects(:puts).with('the message').
          when(printed.is(:nothing)).then(printed.is(:message))
        @subject.expects(:puts).with('the', 'backtrace').
          when(printed.is(:message)).then(printed.is(:done))

        @subject.run(%w(--verbose))
      end

      it 'exits with a failure status when an InformativeError occurs' do
        @subject.expects(:exit).with(1)
        @subject.any_instance.stubs(:validate!).
          raises(Fixture::Error.new)
        @subject.run([])
      end

      it 'exits with a failure status when a Help exception occurs' do
        @subject.expects(:exit).with(1)
        @subject.run(%w(unknown))
      end

      it 'exits with a success status when an empty Help exception occurs' do
        @subject.expects(:exit).with(0)
        @subject.run(%w(--help))
      end

      it 'allows clients to customize how to report exceptions' do
        exception = Exception.new('message')
        @subject.any_instance.expects(:run).raises(exception)
        @subject.expects(:report_error).with(exception)
        @subject.run
      end

      it 'raises by default' do
        should.raise do
          @subject.run
        end.message.should.match /subclass should override/
      end
    end

    #-------------------------------------------------------------------------#

    describe 'default_subcommand' do

      before do
        @command_class = @subject::SpecFile.dup
        @command_class.default_subcommand = 'lint'
      end

      it 'returns the default subcommand if specified' do
        cmd = @command_class.parse([])
        cmd.class.should == @subject::SpecFile::Lint
      end

      it "doesn't return a default subcommand if a command is given" do
        cmd = @command_class.parse(%w(create))
        cmd.class.should == @subject::SpecFile::Create
      end

      it "doesn't invoke a default subcommand by default" do
        @command_class.default_subcommand = nil
        cmd = @command_class.parse([])
        cmd.class.should == @command_class
      end

      it 'invokes the default subcommand only if abstract' do
        @command_class.abstract_command = false
        cmd = @command_class.parse([])
        cmd.class.should == @command_class
      end

      it 'raises if unable to find the default subcommand' do
        command_class = @subject::SpecFile.dup
        command_class.default_subcommand = 'find-me'
        should.raise do
          command_class.parse([])
        end.message.should.match /Unable to find the default subcommand/
      end

      it 'shows the help of the parent if a command was invoked by default' do
        cmd = @command_class.parse([])
        cmd.class.superclass.expects(:help!)
        cmd.send(:help!)
      end

      it "doesn't show the help of the parent by default" do
        cmd = @command_class.parse(%w(create))
        cmd.class.expects(:help!)
        cmd.send(:help!)
      end
    end
  end
end
