require 'bacon'
require 'mocha-on-bacon'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'active_support/core_ext/string/inflections'
require 'cli_aide'


def should_raise_help(error_message)
  error = nil
  begin
    yield
  rescue CLIAide::Command::Help => e
    error = e
  end
  error.should.not == nil
  error.error_message.should == error_message
end

module CLIAide
  describe ARGV do
    before do
      @argv = ARGV.new(%w{ --flag --option VALUE ARG1 ARG2 --no-other-flag })
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
      @argv.remainder.should == %w{ --option VALUE ARG1 ARG2 }
    end

    it "returns an option and deletes it" do
      @argv.option('flag').should == nil
      @argv.option('other-flag').should == nil
      @argv.option('option').should == 'VALUE'
      @argv.remainder.should == %w{ --flag ARG1 ARG2 --no-other-flag }
    end

    it "returns the first argument and deletes it" do
      @argv.shift_argument.should == 'ARG1'
      @argv.remainder.should == %w{ --flag --option VALUE ARG2 --no-other-flag }
    end
  end
end

module Fixture
  class Command < CLIAide::Command
    def self.binname
      'bin'
    end

    class SpecFile < Command
      class Lint < SpecFile
        self.description = 'Checks the validity of a spec file.'
        self.arguments = '[NAME]'

        def self.options
          [['--only-errors', 'Skip warnings']].concat(super)
        end

        class Repo < Lint
          self.description = 'Checks the validity of ALL specs in a repo.'
        end
      end

      class Create < SpecFile
        self.description = 'Creates a spec file stub.'

        attr_reader :spec
        def initialize(argv)
          @spec = argv.shift_argument
          super
        end

        def run
          # This command actully does something.
        end
      end
    end
  end
end

module CLIAide
  describe Command do
    it "registers the subcommand classes" do
      Fixture::Command.subcommands.map(&:command).should == %w{ spec-file }
      Fixture::Command::SpecFile.subcommands.map(&:command).should == %w{ lint create }
      Fixture::Command::SpecFile::Create.subcommands.map(&:command).should == []
      Fixture::Command::SpecFile::Lint.subcommands.map(&:command).should == %w{ repo }
    end

    it "tries to match a subclass for each of the subcommands" do
      Fixture::Command.parse(%w{ spec-file }).should.be.instance_of Fixture::Command::SpecFile
      Fixture::Command.parse(%w{ spec-file lint }).should.be.instance_of Fixture::Command::SpecFile::Lint
      Fixture::Command.parse(%w{ spec-file lint repo }).should.be.instance_of Fixture::Command::SpecFile::Lint::Repo
    end

    # TODO might be more the task of the application?
    #it "raises a Help exception when run without any subcommands" do
      #lambda { Fixture::Command.run([]) }.should.raise Command::Help
    #end

    it "does not raise if one of the subcommands consumes arguments" do
      subcommand = Fixture::Command.parse(%w{ spec-file create AFNetworking })
      subcommand.spec.should == 'AFNetworking'
    end

    it "raises a Help exception when created with an invalid subcommand" do
      should_raise_help 'Unknown arguments: unknown' do
        Fixture::Command.parse(%w{ unknown }).validate_argv!
      end
      should_raise_help 'Unknown arguments: unknown' do
        Fixture::Command.parse(%w{ spec-file unknown }).validate_argv!
      end
    end

    it "raises a Help exception (without error message) when running a command that does not itself implement #run" do
      should_raise_help nil do
        Fixture::Command.parse(%w{ spec-file }).run
      end
    end
  end

  describe Command, "default options" do
    it "raises a Help exception, without error message" do
      should_raise_help nil do
        Fixture::Command.parse(%w{ --help }).validate_argv!
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

    it "does not print the backtrace of a Informative exception by default" do
      expected = Command::Help.new(Fixture::Command).message
      Fixture::Command.expects(:puts).with(expected)
      Fixture::Command.run(%w{ --help })
    end

    it "does print the backtrace of a Informative exception if set to verbose" do
      error = Command::Informative.new
      Fixture::Command.any_instance.stubs(:validate_argv!).raises(error)
      error.stubs(:message).returns('the message')
      error.stubs(:backtrace).returns(['the', 'backtrace'])

      printed = states('printed').starts_as(:nothing)
      Fixture::Command.expects(:puts).with('the message').when(printed.is(:nothing)).then(printed.is(:message))
      Fixture::Command.expects(:puts).with('the', 'backtrace').when(printed.is(:message)).then(printed.is(:done))

      Fixture::Command.run(%w{ --verbose })
    end

    it "exits with a failure status when an Informative exception occurs" do
      Fixture::Command.expects(:exit).with(1)
      Fixture::Command.any_instance.stubs(:validate_argv!).raises(Command::Informative.new)
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

    it "exits with a failure status when any other type of exception occurs" do
      Fixture::Command.expects(:exit).with(1)
      Fixture::Command.any_instance.stubs(:validate_argv!).raises(ArgumentError.new)
      Fixture::Command.run([])
    end
  end

  describe Command, "formatting" do
    it "returns the subcommands, sorted by name" do
      Fixture::Command::SpecFile.formatted_subcommands_description.should == <<-COMMANDS.rstrip
    $ bin spec-file create

      Creates a spec file stub.

    $ bin spec-file lint [NAME]

      Checks the validity of a spec file.
COMMANDS
    end

    it "returns the options, for all ancestor commands, aligned so they're all aligned with the largest option name" do
      Fixture::Command::SpecFile.formatted_options_description.should == <<-OPTIONS.rstrip
    --verbose   Show more debugging information
    --help      Show help banner
OPTIONS
      Fixture::Command::SpecFile::Lint::Repo.formatted_options_description.should == <<-OPTIONS.rstrip
    --only-errors   Skip warnings
    --verbose       Show more debugging information
    --help          Show help banner
OPTIONS
    end
  end

  describe Command::Help, "formatting" do
    it "shows the command's own description, those of the subcommands, and of the options" do
      Command::Help.new(Fixture::Command::SpecFile::Lint).message.should == <<-BANNER.rstrip
Usage:

    $ bin spec-file lint [NAME]

      Checks the validity of a spec file.

Commands:

    $ bin spec-file lint repo

      Checks the validity of ALL specs in a repo.

Options:

    --only-errors   Skip warnings
    --verbose       Show more debugging information
    --help          Show help banner
BANNER
    end

    it "shows the specified error message before the rest of the banner" do
      Command::Help.new(Fixture::Command, "Unable to process, captain.").message.should == <<-BANNER.rstrip
[!] Unable to process, captain.

Options:

    --verbose   Show more debugging information
    --help      Show help banner
BANNER
    end
  end
end
