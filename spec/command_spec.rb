# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

module CLAide
  describe Command do

    before do
      @command = Fixture::Command
    end

    describe 'in general' do
      it 'registers the subcommand classes' do
        @command.subcommands.map(&:command).should ==
          %w(spec-file)
        @command::SpecFile.subcommands.map(&:command).should ==
          %w(common-invisible-command)
        @command::SpecFile::Create.subcommands.map(&:command).should ==
          []
        @command::SpecFile::Lint.subcommands.map(&:command).should ==
          %w(repo)
      end

      it 'returns subcommands for look up' do
        subcommands = @command::SpecFile.subcommands_for_command_lookup
        subcommands.map(&:command).should == %w(lint create)
      end

      it 'returns whether it is the root command' do
        @command.should.be.root_command?
        @command::SpecFile.should.not.be.root_command?
      end

      it 'tries to match a subclass for each of the subcommands' do
        parsed = @command.parse(%w(spec-file --verbose lint))
        parsed.should.be.instance_of @command::SpecFile::Lint
      end

      it 'returns the signature arguments' do
        @command::SpecFile::Lint.arguments.should == [
          CLAide::Argument.new('NAME', false),
        ]
      end
    end

    #-------------------------------------------------------------------------#

    describe 'class methods' do
      it 'returns that ANSI output should be used if a TTY is present' do
        @command.ansi_output = nil
        STDOUT.expects(:tty?).returns(true)
        @command.ansi_output.should.be.true
      end

      it 'returns that ANSI output should be used if a TTY is not present' do
        @command.ansi_output = nil
        STDOUT.expects(:tty?).returns(false)
        @command.ansi_output.should.be.false
      end

      it 'invokes a command with the convenience method and args list' do
        @command::SpecFile.any_instance.expects(:validate!)
        @command::SpecFile.any_instance.expects(:run).once

        @command::SpecFile.invoke('arg1', 'arg2')

        argv = @command::SpecFile.latest_instance.instance_eval { @argv }
        argv.should.be.an.instance_of? CLAide::ARGV
        argv.arguments.should == %w(arg1 arg2)
      end

      it 'invokes a command with the convenience method and array args' do
        @command::SpecFile.any_instance.expects(:validate!)
        @command::SpecFile.any_instance.expects(:run).once

        @command::SpecFile.invoke %w(arg1 arg2)

        argv = @command::SpecFile.latest_instance.instance_eval { @argv }
        argv.should.be.an.instance_of? CLAide::ARGV
        argv.arguments.should == %w(arg1 arg2)
      end

      it 'raise when invoking a bad command with the convenience method' do
        error = Fixture::Error.new('validate! did raise')
        @command::SpecFile.any_instance.stubs(:validate!).raises(error)

        should.raise Fixture::Error do
          @command::SpecFile.invoke('arg1', 'arg2')
        end.message.should.match /validate! did raise/
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

          prefix = Fixture::CommandPluginable.plugin_prefix
          Command::PluginsHelper.load_plugins(prefix)
          plugin_command = Fixture::CommandPluginable.subcommands.find do |cmd|
            cmd.command == 'demo-plugin'
          end
          plugin_command.should.not.be.nil
          plugin_command.ancestors.should.include Fixture::CommandPluginable
          plugin_command.description.should =~ /plugins/
        end

        it 'is available for help' do
          prefix = Fixture::CommandPluginable.plugin_prefix
          Command::PluginsHelper.load_plugins(prefix)
          banner = CLAide::Command::Banner.new(Fixture::CommandPluginable)
          banner.formatted_banner.should =~ /demo-plugin/
        end
      end

      it 'fails normally if there is no plugin' do
        Command::PluginsHelper.load_plugins(@command.plugin_prefix)
        @command.subcommands.find do
          |cmd| cmd.name == 'demo-plugin'
        end.should.be.nil
      end

      describe 'failing plugins' do
        it 'rescues exceptions raised during the load of the plugin' do
          path = ROOT + 'spec/fixture/command/load_error_plugin_fixture.rb'
          should.raise LoadError do
            require path
          end

          Gem.stubs(:find_latest_files).returns([path])
          should.not.raise do
            Command::PluginsHelper.load_plugins(@command.plugin_prefix)
          end
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe 'validation' do
      it 'does not raise if one of the subcommands consumes arguments' do
        subcommand = @command.parse(%w(spec-file create AFNetworking))
        subcommand.spec.should == 'AFNetworking'
      end

      it 'raises a Help exception when created with an invalid subcommand' do
        message = "Unknown command: `unknown`\nDid you mean: spec-file"
        should_raise_help message do
          @command.parse(%w(unknown)).validate!
        end

        should_raise_help "Unknown command: `unknown`\nDid you mean: lint" do
          @command.parse(%w(spec-file unknown)).validate!
        end
      end

      it 'raises an empty Help exception when called on an abstract command' do
        should_raise_help nil do
          @command.parse(%w(spec-file)).validate!
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe 'default options' do
      before do
        @command.stubs(:puts)
      end

      it 'raises a Help exception, without error message' do
        should.raise SystemExit do
          @command.parse(%w(--help)).validate!
        end
      end

      it 'configures whether ANSI output is enabled' do
        ANSI.expects(:disabled=).with(true)
        @command.any_instance.expects(:validate!)
        @command.any_instance.expects(:run)
        @command.run(%w(--help --no-ansi))
      end

      it 'sets the verbose flag' do
        command = @command.parse([])
        command.should.not.be.verbose
        command = @command.parse(%w(--verbose))
        command.should.be.verbose
      end

      it 'does not runs the instance if root options have been specified' do
        Command::Options.expects(:handle_root_option).returns(true)
        @command.any_instance.expects(:run).never
        @command.run(%w(--version))
      end
    end

    #-------------------------------------------------------------------------#

    describe 'when running' do
      before do
        @command.stubs(:puts)
      end

      it 'invokes an instance of the parsed subcommand' do
        @command::SpecFile.any_instance.stubs(:validate!)
        @command::SpecFile.any_instance.expects(:run)
        @command.run(%w(spec-file))
      end

      it 'does not print the backtrace of an InformativeError by default' do
        ::CLAide::ANSI.disabled = true
        expected = Help.new(@command.banner).message
        @command.expects(:puts).with(expected)
        should.raise SystemExit do
          @command.run(%w(--help))
        end
      end

      it 'does not print the backtrace if help and verbose are set' do
        ::CLAide::ANSI.disabled = true
        expected = Help.new(@command.banner).message
        @command.expects(:puts).with(expected)
        should.raise SystemExit do
          @command.run(%w(--help --verbose))
        end
      end

      it 'prints the backtrace of an InformativeError, if set to verbose' do
        error = Fixture::Error.new
        @command.any_instance.stubs(:validate!).raises(error)
        error.stubs(:message).returns('the message')
        error.stubs(:backtrace).returns(%w(the backtrace))

        printed = states('printed').starts_as(:nothing)
        @command.expects(:puts).with('the message').
          when(printed.is(:nothing)).then(printed.is(:message))
        @command.expects(:puts).with('the', 'backtrace').
          when(printed.is(:message)).then(printed.is(:done))

        should.raise SystemExit do
          @command.run(%w(--verbose))
        end
      end

      it 'exits with a failure status when an InformativeError occurs' do
        @command.expects(:exit).with(1)
        @command.any_instance.stubs(:validate!).
          raises(Fixture::Error.new)
        @command.run([])
      end

      it 'exits with a failure status when a Help exception occurs' do
        @command.expects(:exit).with(1)
        @command.run(%w(unknown))
      end

      it 'exits with a success status when an empty Help exception occurs' do
        @command.expects(:exit).with(0)
        @command.any_instance.stubs(:run) # by mocking exit, we reach run
        @command.run(%w(--help))
      end

      it 'allows clients to customize how to report exceptions' do
        exception = Exception.new('message')
        @command.any_instance.expects(:run).raises(exception)
        @command.expects(:report_error).with(exception)
        @command.run
      end

      it 'raises by default' do
        should.raise do
          @command.run
        end.message.should.match /subclass should override/
      end
    end

    #-------------------------------------------------------------------------#

    describe 'help' do
      before do
        @command_class = @command::SpecFile.dup
        @command_class.default_subcommand = 'lint'
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

  describe '::parse' do
    before do
      @command_class = Fixture::Command::SpecFile
    end

    it 'tries to match a subclass for each of the subcommands' do
      parsed = @command_class.parse(%w(--verbose lint))
      parsed.should.be.instance_of Fixture::Command::SpecFile::Lint
    end

    it 'invokes the default subcommand only if abstract' do
      @command_class.default_subcommand = 'lint'
      @command_class.abstract_command = false
      cmd = @command_class.parse([])
      cmd.class.should == @command_class
    end

    it "doesn't return a default subcommand if a command is given" do
      @command_class.default_subcommand = 'lint'
      cmd = @command_class.parse(%w(create))
      cmd.class.should == Fixture::Command::SpecFile::Create
    end

    it "doesn't invoke a default subcommand by default" do
      @command_class.default_subcommand = nil
      cmd = @command_class.parse([])
      cmd.class.should == @command_class
    end
  end

  describe '::load_default_subcommand' do
    before do
      @command_class = Fixture::Command::SpecFile.dup
      @command_class.default_subcommand = 'lint'
    end

    it 'returns the default subcommand if specified' do
      cmd = @command_class.load_default_subcommand([])
      cmd.class.should == Fixture::Command::SpecFile::Lint
    end

    it 'raises if unable to find the default subcommand' do
      @command_class.default_subcommand = 'find-me'
      should.raise do
        @command_class.load_default_subcommand([])
      end.message.should.match /Unable to find the default subcommand/
    end

    it 'marks the command as invoked by default' do
      cmd = @command_class.load_default_subcommand([])
      cmd.invoked_as_default.should.be.true
    end
  end
end
