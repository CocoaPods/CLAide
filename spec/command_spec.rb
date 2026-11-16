# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

module CLAide
  describe Command do
    before do
      @command = Fixture::Command
    end

    describe 'in general' do
      it 'registers the subcommand classes' do
        expect(@command.subcommands.map(&:command)).to eq(%w(spec-file))
        expect(@command::SpecFile.subcommands.map(&:command)).
          to eq(%w(common-invisible-command))
        expect(@command::SpecFile::Create.subcommands.map(&:command)).to eq([])
        expect(@command::SpecFile::Lint.subcommands.map(&:command)).
          to eq(%w(repo))
      end

      it 'returns subcommands for look up' do
        subcommands = @command::SpecFile.subcommands_for_command_lookup
        expect(subcommands.map(&:command)).to eq(%w(lint create))
      end

      it 'returns whether it is the root command' do
        expect(@command).to be_root_command
        expect(@command::SpecFile).not_to be_root_command
      end

      it 'tries to match a subclass for each of the subcommands' do
        parsed = @command.parse(%w(spec-file --verbose lint))
        expect(parsed).to be_an_instance_of(@command::SpecFile::Lint)
      end

      it 'returns the signature arguments' do
        expected = [
          CLAide::Argument.new('NAME', false),
        ]
        expect(@command::SpecFile::Lint.arguments).to eq(expected)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'class methods' do
      it 'returns that ANSI output should be used if a TTY is present' do
        @command.ansi_output = nil
        STDOUT.expects(:tty?).returns(true)
        expect(@command.ansi_output).to be(true)
      end

      it 'returns that ANSI output should be used if a TTY is not present' do
        @command.ansi_output = nil
        STDOUT.expects(:tty?).returns(false)
        expect(@command.ansi_output).to be(false)
      end

      it 'invokes a command with the convenience method and args list' do
        @command::SpecFile.any_instance.expects(:validate!)
        @command::SpecFile.any_instance.expects(:run).once

        @command::SpecFile.invoke('arg1', 'arg2')

        argv = @command::SpecFile.latest_instance.instance_eval { @argv }
        expect(argv).to be_an_instance_of(CLAide::ARGV)
        expect(argv.arguments).to eq(%w(arg1 arg2))
      end

      it 'invokes a command with the convenience method and array args' do
        @command::SpecFile.any_instance.expects(:validate!)
        @command::SpecFile.any_instance.expects(:run).once

        @command::SpecFile.invoke %w(arg1 arg2)

        argv = @command::SpecFile.latest_instance.instance_eval { @argv }
        expect(argv).to be_an_instance_of(CLAide::ARGV)
        expect(argv.arguments).to eq(%w(arg1 arg2))
      end

      it 'raise when invoking a bad command with the convenience method' do
        error = Fixture::Error.new('validate! did raise')
        @command::SpecFile.any_instance.stubs(:validate!).raises(error)

        expect do
          @command::SpecFile.invoke('arg1', 'arg2')
        end.to raise_error(Fixture::Error, /validate! did raise/)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'plugins' do
      # The plugin file is really required, so `is available for help` relies
      # on `loads the plugin` having run first.
      describe 'when the plugin is at <command-prefix>_plugin.rb',
               :order => :defined do
        before do
          Command::PluginManager.instance_variable_set(:@loaded_plugins, nil)
          path = ROOT + 'spec/fixture/command/fixture_plugin.rb'
          spec = SpecHelper::RubyGems.fixture_spec_with_file(path)
          SpecHelper::RubyGems.stub_latest_specs(spec)
        end

        it 'loads the plugin' do
          expect(Fixture::CommandPluginable.subcommands.find do |cmd|
            cmd.command == 'demo-plugin'
          end).to be_nil

          prefix = Fixture::CommandPluginable.plugin_prefixes.last
          Command::PluginManager.load_plugins(prefix)
          plugin_command = Fixture::CommandPluginable.subcommands.find do |cmd|
            cmd.command == 'demo-plugin'
          end
          expect(plugin_command).not_to be_nil
          expect(plugin_command.ancestors).
            to include(Fixture::CommandPluginable)
          expect(plugin_command.description).to match(/plugins/)
        end

        it 'is available for help' do
          prefix = Fixture::CommandPluginable.plugin_prefixes.last
          Command::PluginManager.load_plugins(prefix)
          banner = CLAide::Command::Banner.new(Fixture::CommandPluginable)
          expect(banner.formatted_banner).to match(/demo-plugin/)
        end
      end

      it 'fails normally if there is no plugin' do
        Command::PluginManager.load_plugins(@command.plugin_prefixes.last)
        expect(@command.subcommands.find do |cmd|
          cmd.name == 'demo-plugin'
        end).to be_nil
      end

      describe 'failing plugins' do
        it 'rescues exceptions raised during the load of the plugin' do
          path = ROOT + 'spec/fixture/command/load_error_plugin_fixture.rb'
          expect do
            require path
          end.to raise_error(LoadError)

          Gem.stubs(:find_latest_files).returns([path])
          expect do
            Command::PluginManager.load_plugins(@command.plugin_prefixes.last)
          end.not_to raise_error
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe 'validation' do
      it 'does not raise if one of the subcommands consumes arguments' do
        subcommand = @command.parse(%w(spec-file create AFNetworking))
        expect(subcommand.spec).to eq('AFNetworking')
      end

      it 'raises a Help exception when created with an invalid subcommand' do
        message = "Unknown command: `unknown`\nDid you mean: spec-file?"
        should_raise_help message do
          @command.parse(%w(unknown)).validate!
        end

        should_raise_help "Unknown command: `unknown`\nDid you mean: lint?" do
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
        expect do
          @command.parse(%w(--help)).validate!
        end.to raise_error(SystemExit)
      end

      it 'configures whether ANSI output is enabled' do
        ANSI.expects(:disabled=).with(true)
        @command.any_instance.expects(:validate!)
        @command.any_instance.expects(:run)
        @command.run(%w(--help --no-ansi))
      end

      it 'sets the verbose flag' do
        command = @command.parse([])
        expect(command).not_to be_verbose
        command = @command.parse(%w(--verbose))
        expect(command).to be_verbose
      end

      it 'does not runs the instance if root options have been specified' do
        instance = @command.any_instance
        instance.expects(:handle_root_options).returns(true)
        instance.expects(:run).never
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
        expect do
          @command.run(%w(--help))
        end.to raise_error(SystemExit)
      end

      it 'does not print the backtrace if help and verbose are set' do
        ::CLAide::ANSI.disabled = true
        expected = Help.new(@command.banner).message
        @command.expects(:puts).with(expected)
        expect do
          @command.run(%w(--help --verbose))
        end.to raise_error(SystemExit)
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

        expect do
          @command.run(%w(--verbose))
        end.to raise_error(SystemExit)
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
        expect do
          @command.run
        end.to raise_error(RuntimeError, /subclass should override/)
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

      it 'remembers if --help was specified' do
        args = ARGV.coerce(%w(create --help))
        cmd = @command_class.new(args)
        args.remainder!
        cmd.expects(:banner!).once
        cmd.stubs(:help!)
        cmd.send(:validate!)
      end
    end
  end

  describe '::parse' do
    before do
      @command_class = Fixture::Command::SpecFile.dup
    end

    it 'tries to match a subclass for each of the subcommands' do
      parsed = @command_class.parse(%w(--verbose lint))
      expect(parsed).to be_an_instance_of(Fixture::Command::SpecFile::Lint)
    end

    it 'invokes the default subcommand only if abstract' do
      @command_class.default_subcommand = 'lint'
      @command_class.abstract_command = false
      cmd = @command_class.parse([])
      expect(cmd.class).to eq(@command_class)
    end

    it "doesn't return a default subcommand if a command is given" do
      @command_class.default_subcommand = 'lint'
      cmd = @command_class.parse(%w(create))
      expect(cmd.class).to eq(Fixture::Command::SpecFile::Create)
    end

    it "doesn't invoke a default subcommand by default" do
      @command_class.default_subcommand = nil
      cmd = @command_class.parse([])
      expect(cmd.class).to eq(@command_class)
    end
  end

  describe '::load_default_subcommand' do
    before do
      @command_class = Fixture::Command::SpecFile.dup
      @command_class.default_subcommand = 'lint'
    end

    it 'returns the default subcommand if specified' do
      cmd = @command_class.load_default_subcommand([])
      expect(cmd.class).to eq(Fixture::Command::SpecFile::Lint)
    end

    it 'raises if unable to find the default subcommand' do
      @command_class.default_subcommand = 'find-me'
      expect do
        @command_class.load_default_subcommand([])
      end.to raise_error(RuntimeError, /Unable to find the default subcommand/)
    end

    it 'marks the command as invoked by default' do
      cmd = @command_class.load_default_subcommand([])
      expect(cmd.invoked_as_default).to be(true)
    end
  end

  describe 'concerning options' do
    describe '::options' do
      it 'returns root options for root commands' do
        options = Fixture::Command.options.map(&:first)
        expect(options).to include('--verbose')
        expect(options).to include('--version')
      end

      it 'does not return root options for non-root commands' do
        options = Fixture::Command::SpecFile.options.map(&:first)
        expect(options).to include('--verbose')
        expect(options).not_to include('--version')
      end
    end

    describe '.option' do
      before do
        @command_class = Class.new(Fixture::Command)
      end

      after do
        Fixture::Command.subcommands.delete(@command_class)
      end

      it 'adds the option' do
        @command_class.module_eval do
          option '--foo', 'Does the thing'
        end

        options = @command_class.options
        expect(options).to include(['--foo', 'Does the thing'])
      end

      it 'allows removing the option' do
        @command_class.module_eval do
          option '--foo', 'Does the thing'
        end

        command_class = Class.new(@command_class) do
          def self.options
            super.reject { |n, _d| n == '--foo' }
          end
        end

        options = command_class.options
        expect(options).not_to include(['--foo', 'Does the thing'])
      end
    end

    describe '::handle_root_options' do
      before do
        @version_flag = ARGV.new(['--version'])
      end

      it 'handles the version flag' do
        command = Fixture::Command.new([])
        command.expects(:print_version)
        expect(command.handle_root_options(@version_flag)).to be(true)
      end

      it 'does not handle the version flag for non root commands' do
        command = Fixture::Command::SpecFile.new([])
        command.expects(:print_version).never
        expect(command.handle_root_options(@version_flag)).to be(false)
      end
    end

    describe '#print_version' do
      it 'prints the version' do
        command = Fixture::Command.new(%w(--version))
        command.class.version = '1.0'
        command.expects(:puts).with('1.0')
        command.print_version
      end

      it 'includes plugins version if the verbose flag has been specified' do
        spec = stub(:name => 'cocoapods_plugin', :version => '1.0')
        Command::PluginManager.expects(:specifications).returns([spec])

        command = Fixture::Command.new(%w(--version --verbose))
        command.class.version = '1.0'
        command.expects(:puts).with('1.0')
        command.expects(:puts).with('cocoapods_plugin: 1.0')
        command.print_version
      end
    end
  end
end
