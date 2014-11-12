# encoding: utf-8

module Fixture
  class Error < StandardError
    include CLAide::InformativeError
  end

  class Command < CLAide::Command
    self.command = 'bin'
    self.ansi_output = false

    class << self
      attr_accessor :latest_instance
    end

    def initialize(*args)
      self.class.latest_instance = self
      super
    end

    class SpecFile < Command
      self.abstract_command = true
      self.description = 'Manage spec files.'

      class CommonInvisibleCommand < SpecFile
        self.ignore_in_command_lookup = true
      end

      class Lint < CommonInvisibleCommand
        self.summary = 'Checks the validity of a spec file.'
        self.arguments = [
          CLAide::Argument.new('NAME', false),
        ]

        def self.options
          [['--only-errors', 'Skip warnings']].concat(super)
        end

        class Repo < Lint
          self.summary = 'Checks the validity of ALL specs in a repo.'
        end
      end

      class Create < CommonInvisibleCommand
        self.summary = 'Creates a spec file stub.'
        self.description = <<-DESC
          Creates a spec file called NAME
          and populates it with defaults.
        DESC
        self.arguments = [
          CLAide::Argument.new('NAME', false),
        ]

        attr_reader :spec
        def initialize(argv)
          @spec = argv.shift_argument
          super
        end
      end
    end
  end

  class CommandPluginable < CLAide::Command
    plugin_prefixes << 'fixture'
    self.ansi_output = false
  end
end
