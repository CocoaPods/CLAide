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

  end
end
