require File.expand_path('../spec_helper', __FILE__)

module CLAide
  describe Command do

    describe "in general" do
      it "registers the subcommand classes" do
        Fixture::Command.subcommands.map(&:command).should == %w{ spec-file }
        Fixture::Command::SpecFile.subcommands.map(&:command).should == %w{ lint create }
        Fixture::Command::SpecFile::Create.subcommands.map(&:command).should == []
        Fixture::Command::SpecFile::Lint.subcommands.map(&:command).should == %w{ repo }
      end

      it "tries to match a subclass for each of the subcommands" do
        #Fixture::Command.parse(%w{ spec-file }).should.be.instance_of Fixture::Command::SpecFile
        Fixture::Command.parse(%w{ spec-file --verbose lint }).should.be.instance_of Fixture::Command::SpecFile::Lint
        #Fixture::Command.parse(%w{ spec-file lint --help repo }).should.be.instance_of Fixture::Command::SpecFile::Lint::Repo
      end

      describe "plugins" do
        describe "when the plugin is at <command-prefix>_plugin.rb" do
          PLUGIN_FIXTURE = Pathname.new(ROOT) + 'spec/fixture/command/plugin_fixture.rb'
          PLUGIN = Pathname.new(ROOT) + 'spec/fixture_plugin.rb'

          before do
            FileUtils.copy PLUGIN_FIXTURE, PLUGIN
          end

          after do
            FileUtils.remove_file PLUGIN
          end

          it "loads the plugin" do
            Fixture::Command.subcommands.find {|subcmd| subcmd.command == 'demo-plugin'}.should.be.nil
            Fixture::Command.load_plugins
            plugin_class = Fixture::Command.subcommands.find {|subcmd| subcmd.command == 'demo-plugin'}
            plugin_class.ancestors.should.include Fixture::Command
            plugin_class.description.should =~ /plugins/
          end

          it "is available for help" do
            Fixture::Command.load_plugins
            CLAide::Command::Banner.new(Fixture::Command, false).formatted_banner.should =~ /demo-plugin/
          end
        end

        it "fails normally if there is no plugin" do
          Fixture::Command.load_plugins
          Fixture::Command.subcommands.find {|subcmd| subcmd.name == 'demo-plugin' }.should.be.nil
        end
      end
    end

    #-------------------------------------------------------------------------#

    # TODO might be more the task of the application?
    #it "raises a Help exception when run without any subcommands" do
    #lambda { Fixture::Command.run([]) }.should.raise Command::Help
    #end

    describe "validation" do
      it "does not raise if one of the subcommands consumes arguments" do
        subcommand = Fixture::Command.parse(%w{ spec-file create AFNetworking })
        subcommand.spec.should == 'AFNetworking'
      end

      it "raises a Help exception when created with an invalid subcommand" do
        should_raise_help 'Unknown arguments: unknown' do
          Fixture::Command.parse(%w{ unknown }).validate!
        end
        should_raise_help 'Unknown arguments: unknown' do
          Fixture::Command.parse(%w{ spec-file unknown }).validate!
        end
      end

      it "raises a Help exception (without error message) when called on an abstract command" do
        should_raise_help nil do
          Fixture::Command.parse(%w{ spec-file }).validate!
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe "default options" do
      it "raises a Help exception, without error message" do
        should_raise_help nil do
          Fixture::Command.parse(%w{ --help }).validate!
        end
      end

      it "sets the verbose flag" do
        command = Fixture::Command.parse([])
        command.should.not.be.verbose
        command = Fixture::Command.parse(%w{ --verbose })
        command.should.be.verbose
      end
    end

    #-------------------------------------------------------------------------#

    describe "when running" do
      before do
        Fixture::Command.stubs(:puts)
        Fixture::Command.stubs(:exit)
      end

      it "does not print the backtrace of a InformativeError exception by default" do
        expected = Help.new(Fixture::Command.banner).message
        Fixture::Command.expects(:puts).with(expected)
        Fixture::Command.run(%w{ --help })
      end

      it "does print the backtrace of an exception, that includes InformativeError, if set to verbose" do
        error = Fixture::Error.new
        Fixture::Command.any_instance.stubs(:validate!).raises(error)
        error.stubs(:message).returns('the message')
        error.stubs(:backtrace).returns(['the', 'backtrace'])

        printed = states('printed').starts_as(:nothing)
        Fixture::Command.expects(:puts).with('the message').when(printed.is(:nothing)).then(printed.is(:message))
        Fixture::Command.expects(:puts).with('the', 'backtrace').when(printed.is(:message)).then(printed.is(:done))

        Fixture::Command.run(%w{ --verbose })
        end

      it "exits with a failure status when an exception that includes InformativeError occurs" do
        Fixture::Command.expects(:exit).with(1)
        Fixture::Command.any_instance.stubs(:validate!).raises(Fixture::Error.new)
        Fixture::Command.run([])
      end

      it "exits with a failure status when a Help exception occurs that has an error message" do
        Fixture::Command.expects(:exit).with(1)
        Fixture::Command.run(%w{ unknown })
      end

      it "exits with a success status when a Help exception occurs that has *no* error message" do
        Fixture::Command.expects(:exit).with(0)
        Fixture::Command.run(%w{ --help })
      end

      #it "exits with a failure status when any other type of exception occurs" do
      #Fixture::Command.expects(:exit).with(1)
      #Fixture::Command.any_instance.stubs(:validate!).raises(ArgumentError.new)
      #Fixture::Command.run([])
      #end
    end

    #-------------------------------------------------------------------------#

    describe "default_subcommand" do

      before do
        @command_class = Fixture::Command::SpecFile.dup
        @command_class.default_subcommand = 'lint'
      end

      it "returns the default subcommand if specified" do
        cmd = @command_class.parse([])
        cmd.class.should == Fixture::Command::SpecFile::Lint
      end

      it "doesn't invoke a default subcommand the name of a subcommand is passes in the arguments" do
        cmd = @command_class.parse(%w{ create })
        cmd.class.should == Fixture::Command::SpecFile::Create
      end

      it "doesn't invoke a default subcommand by default" do
        @command_class.default_subcommand = nil
        cmd = @command_class.parse([])
        cmd.class.should == @command_class
      end

      it "invokes the default subcommand only if abstract" do
        @command_class.abstract_command = false
        cmd = @command_class.parse([])
        cmd.class.should == @command_class
      end

      it "raises if unable to find the default subcommand" do
        command_class = Fixture::Command::SpecFile.dup
        @command_class.default_subcommand = 'find-me'
        should.raise do
          cmd = @command_class.parse([])
        end.message.should.match /Unable to find the default subcommand/
      end

      #----------------------------------------#

      it "shows the help of the parent if a command was invoked by default" do
        cmd = @command_class.parse([])
        cmd.class.superclass.expects(:help!)
        cmd.send(:help!)
      end

      it "doesn't show the help of the parent if it was not invoked by default" do
        cmd = @command_class.parse(%w{ create })
        cmd.class.expects(:help!)
        cmd.send(:help!)
      end

    end

    #-------------------------------------------------------------------------#

  end
end
