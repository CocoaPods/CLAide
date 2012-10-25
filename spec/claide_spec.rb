require 'bacon'
require 'mocha-on-bacon'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'active_support/core_ext/string/inflections'
require 'claide'

def should_raise_help(error_message)
  error = nil
  begin
    yield
  rescue CLAide::Command::Help => e
    error = e
  end
  error.should.not == nil
  error.error_message.should == error_message
end

module CLAide
  describe ARGV do
    it "converts objects into strings while parsing" do
      flag = stub(:to_s => '--flag')
      arg = stub(:to_s => 'ARG')
      ARGV.new([flag, arg]).remainder.should == %w{ --flag ARG }
    end

    before do
      @argv = ARGV.new(%w{ --flag --option=VALUE ARG1 ARG2 --no-other-flag })
    end

    it "returns the options as a hash" do
      @argv.options.should == {
        'flag' => true,
        'other-flag' => false,
        'option' => 'VALUE'
      }
    end

    it "returns the arguments" do
      @argv.arguments.should == %w{ ARG1 ARG2 }
    end

    it "returns a flag and deletes it" do
      @argv.flag?('flag').should == true
      @argv.flag?('other-flag').should == false
      @argv.flag?('option').should == nil
      @argv.remainder.should == %w{ --option=VALUE ARG1 ARG2 }
    end

    it "returns a default value if a flag does not exist" do
      @argv.flag?('option', true).should == true
      @argv.flag?('option', false).should == false
    end

    it "returns an option and deletes it" do
      @argv.option('flag').should == nil
      @argv.option('other-flag').should == nil
      @argv.option('option').should == 'VALUE'
      @argv.remainder.should == %w{ --flag ARG1 ARG2 --no-other-flag }
    end

    it "returns a default value if an option does not exist" do
      @argv.option('flag', 'value').should == 'value'
    end

    it "returns the first argument and deletes it" do
      @argv.shift_argument.should == 'ARG1'
      @argv.remainder.should == %w{ --flag --option=VALUE ARG2 --no-other-flag }
    end

    it "returns and deletes all arguments" do
      @argv.arguments!.should == %w{ ARG1 ARG2 }
      @argv.remainder.should == %w{ --flag --option=VALUE --no-other-flag }
    end
  end
end

module Fixture
  class Error < StandardError
    include CLAide::Command::InformativeError
  end

  class Command < CLAide::Command
    def self.binname
      'bin'
    end

    class SpecFile < Command
      self.abstract_command = true
      self.description = 'Manage spec files.'

      class Lint < SpecFile
        self.summary = 'Checks the validity of a spec file.'
        self.arguments = '[NAME]'

        def self.options
          [['--only-errors', 'Skip warnings']].concat(super)
        end

        class Repo < Lint
          self.summary = 'Checks the validity of ALL specs in a repo.'
        end
      end

      class Create < SpecFile
        self.summary = 'Creates a spec file stub.'
        self.description = 'Creates a spec file called NAME and populates it with defaults.'
        self.arguments = '[NAME]'

        attr_reader :spec
        def initialize(argv)
          @spec = argv.shift_argument
          super
        end
      end
    end
  end
end

module CLAide
  describe Command do
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

    # TODO might be more the task of the application?
    #it "raises a Help exception when run without any subcommands" do
      #lambda { Fixture::Command.run([]) }.should.raise Command::Help
    #end
  end

  describe Command, "validation" do
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

  describe Command, "default options" do
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

  describe Command, "when running" do
    before do
      Fixture::Command.stubs(:puts)
      Fixture::Command.stubs(:exit)
    end

    it "does not print the backtrace of a InformativeError exception by default" do
      expected = Command::Help.new(Fixture::Command.parse([])).message
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

  describe Command, "banner formatting in general" do
    it "returns a 'usage' description based on the command's description" do
      Fixture::Command::SpecFile::Create.parse([]).formatted_usage_description.should == <<-USAGE.rstrip
    $ bin spec-file create [NAME]

      Creates a spec file called NAME and populates it with defaults.
USAGE
    end

    it "returns a 'usage' description based on the command's summary, if no description is present" do
      Fixture::Command::SpecFile::Lint::Repo.parse([]).formatted_usage_description.should == <<-USAGE.rstrip
    $ bin spec-file lint repo

      Checks the validity of ALL specs in a repo.
USAGE
    end

    it "returns summaries of the subcommands of a command, sorted by name" do
      Fixture::Command::SpecFile.parse([]).formatted_subcommand_summaries.should == <<-COMMANDS.rstrip
    * create   Creates a spec file stub.
    * lint     Checks the validity of a spec file.
COMMANDS
    end

    it "returns the options, for all ancestor commands, aligned so they're all aligned with the largest option name" do
      Fixture::Command::SpecFile.parse([]).formatted_options_description.should == <<-OPTIONS.rstrip
    --verbose   Show more debugging information
    --help      Show help banner of specified command
OPTIONS
      Fixture::Command::SpecFile::Lint::Repo.parse([]).formatted_options_description.should == <<-OPTIONS.rstrip
    --only-errors   Skip warnings
    --verbose       Show more debugging information
    --help          Show help banner of specified command
OPTIONS
    end
  end

  describe Command, "complete banner formatting" do
    it "does not include a 'usage' banner for an abstract command" do
      command = Fixture::Command::SpecFile.parse([])
      command.formatted_banner.should == <<-BANNER.rstrip
Manage spec files.

Commands:

#{command.formatted_subcommand_summaries}

Options:

#{command.formatted_options_description}
BANNER
    end

    it "shows a banner that is a combination of the summary/description, commands, and options" do
      command = Fixture::Command::SpecFile::Create.parse([])
      command.formatted_banner.should == <<-BANNER.rstrip
Usage:

#{command.formatted_usage_description}

Options:

#{command.formatted_options_description}
BANNER
    end
  end

  describe Command::Help, "formatting for a command" do
    it "shows just the banner if no error message is specified" do
      command = Fixture::Command.parse([])
      Command::Help.new(command).message.should == command.formatted_banner
    end

    it "shows the specified error message before the rest of the banner" do
      command = Fixture::Command.parse([])
      Command::Help.new(command, "Unable to process, captain.").message.should == <<-BANNER.rstrip
[!] Unable to process, captain.

#{command.formatted_banner}
BANNER
    end
  end
end
