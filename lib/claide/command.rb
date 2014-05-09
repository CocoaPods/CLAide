# encoding: utf-8

require 'claide/command/banner'
require 'claide/command/plugins_helper'
require 'claide/command/validate_helper'
require 'claide/command/shell_completion_helper'

module CLAide
  # This class is used to build a command-line interface
  #
  # Each command is represented by a subclass of this class, which may be
  # nested to create more granular commands.
  #
  # Following is an overview of the types of commands and what they should do.
  #
  # ### Any command type
  #
  # * Inherit from the command class under which the command should be nested.
  # * Set {Command.summary} to a brief description of the command.
  # * Override {Command.options} to return the options it handles and their
  #   descriptions and prepending them to the results of calling `super`.
  # * Override {Command#initialize} if it handles any parameters.
  # * Override {Command#validate!} to check if the required parameters the
  #   command handles are valid, or call {Command#help!} in case they’re not.
  #
  # ### Abstract command
  #
  # The following is needed for an abstract command:
  #
  # * Set {Command.abstract_command} to `true`.
  # * Subclass the command.
  #
  # When the optional {Command.description} is specified, it will be shown at
  # the top of the command’s help banner.
  #
  # ### Normal command
  #
  # The following is needed for a normal command:
  #
  # * Set {Command.arguments} to the description of the arguments this command
  #   handles.
  # * Override {Command#run} to perform the actual work.
  #
  # When the optional {Command.description} is specified, it will be shown
  # underneath the usage section of the command’s help banner. Otherwise this
  # defaults to {Command.summary}.
  #
  class Command
    class << self
      # @return [Boolean] Indicates whether or not this command can actually
      #         perform work of itself, or that it only contains subcommands.
      #
      attr_accessor :abstract_command
      alias_method :abstract_command?, :abstract_command

      # @return [Boolean] Indicates whether or not this command is used during
      #         command parsing and whether or not it should be shown in the
      #         help banner or to show its subcommands instead.
      #
      #         Setting this to `true` implies it’s an abstract command.
      attr_reader :ignore_in_command_lookup
      alias_method :ignore_in_command_lookup?, :ignore_in_command_lookup
      def ignore_in_command_lookup=(flag)
        @ignore_in_command_lookup = self.abstract_command = flag
      end

      # @return [String] The subcommand which an abstract command should invoke
      #         by default.
      #
      attr_accessor :default_subcommand

      # @return [String] A brief description of the command, which is shown
      #         next to the command in the help banner of a parent command.
      #
      attr_accessor :summary

      # @return [String] A longer description of the command, which is shown
      #         underneath the usage section of the command’s help banner. Any
      #         indentation in this value will be ignored.
      #
      attr_accessor :description

      # @return [String] The prefix for loading CLAide plugins for this
      #         command. Plugins are loaded via their
      #         <plugin_prefix>_plugin.rb file.
      #
      attr_accessor :plugin_prefix

      # @return [String] A list of arguments the command handles. This is shown
      #         in the usage section of the command’s help banner.
      #
      attr_accessor :arguments

      # @return [Boolean] The default value for {Command#ansi_output}. This
      #         defaults to `true` if `STDOUT` is connected to a TTY and
      #         `String` has the instance methods `#red`, `#green`, and
      #         `#yellow` (which are defined by, for instance, the
      #         [colored](https://github.com/defunkt/colored) gem).
      #
      def ansi_output
        if @ansi_output.nil?
          @ansi_output = STDOUT.tty?
        end
        @ansi_output
      end
      attr_writer :ansi_output
      alias_method :ansi_output?, :ansi_output

      # @return [String] The name of the command. Defaults to a snake-cased
      #         version of the class’ name.
      #
      def command
        @command ||= name.split('::').last.gsub(/[A-Z]+[a-z]*/) do |part|
          part.downcase << '-'
        end[0..-2]
      end
      attr_writer :command

      # @return [String] The version of the command. This value will be printed
      #         by the `--version` flag if used for the root command.
      #
      attr_accessor :version
    end

    #-------------------------------------------------------------------------#

    # @return [String] The full command up-to this command, as it would be
    #         looked up during parsing.
    #
    # @note (see #ignore_in_command_lookup)
    #
    # @example
    #
    #   BevarageMaker::Tea.full_command # => "beverage-maker tea"
    #
    def self.full_command
      if superclass == Command
        ignore_in_command_lookup? ? '' : command
      else
        if ignore_in_command_lookup?
          superclass.full_command
        else
          "#{superclass.full_command} #{command}"
        end
      end
    end

    # @return [Bool] Whether this is the root command class
    #
    def self.root_command?
      superclass == CLAide::Command
    end

    # @return [Array<Class>] A list of all command classes that are nested
    #         under this command.
    #
    def self.subcommands
      @subcommands ||= []
    end

    # @return [Array<Class>] A list of command classes that are nested under
    #         this command _or_ the subcommands of those command classes in
    #         case the command class should be ignored in command lookup.
    #
    def self.subcommands_for_command_lookup
      subcommands.map do |subcommand|
        if subcommand.ignore_in_command_lookup?
          subcommand.subcommands_for_command_lookup
        else
          subcommand
        end
      end.flatten
    end

    # Searches the list of subcommands that should not be ignored for command
    # lookup for a subcommand with the given `name`.
    #
    # @param  [String] name
    #         The name of the subcommand to be found.
    #
    # @return [CLAide::Command, nil] The subcommand, if found.
    #
    def self.find_subcommand(name)
      subcommands_for_command_lookup.find { |sc| sc.command == name }
    end

    # @visibility private
    #
    # Automatically registers a subclass as a subcommand.
    #
    def self.inherited(subcommand)
      subcommands << subcommand
    end

    # Should be overridden by a subclass if it handles any options.
    #
    # The subclass has to combine the result of calling `super` and its own
    # list of options. The recommended way of doing this is by concatenating
    # concatenating to this classes’ own options.
    #
    # @return [Array<Array>]
    #
    #   A list of option name and description tuples.
    #
    # @example
    #
    #   def self.options
    #     [
    #       ['--verbose', 'Print more info'],
    #       ['--help',    'Print help banner'],
    #     ].concat(super)
    #   end
    #
    def self.options
      options = [
        ['--verbose', 'Show more debugging information'],
        ['--no-ansi', 'Show output without ANSI codes'],
        ['--help',    'Show help banner of specified command']
      ]

      if root_command?
        options.unshift(
          ['--completion-script',  'Print the auto-completion script'],
          ['--version',            'Show the version of the tool'])
      end

      options
    end

    # @param  [Array, ARGV] argv
    #         A list of (remaining) parameters.
    #
    # @return [Command] An instance of the command class that was matched by
    #         going through the arguments in the parameters and drilling down
    #         command classes.
    #
    def self.parse(argv)
      argv = ARGV.new(argv) unless argv.is_a?(ARGV)
      cmd = argv.arguments.first
      if cmd && subcommand = find_subcommand(cmd)
        argv.shift_argument
        subcommand.parse(argv)
      elsif abstract_command? && default_subcommand
        subcommand = find_subcommand(default_subcommand)
        unless subcommand
          raise 'Unable to find the default subcommand ' \
            "`#{default_subcommand}` for command `#{self}`."
        end
        result = subcommand.parse(argv)
        result.invoked_as_default = true
        result
      else
        new(argv)
      end
    end

    # Instantiates the command class matching the parameters through
    # {Command.parse}, validates it through {Command#validate!}, and runs it
    # through {Command#run}.
    #
    # @note
    #
    #   You should normally call this on
    #
    # @param [Array, ARGV] argv
    #
    #   A list of parameters. For instance, the standard `ARGV` constant,
    #   which contains the parameters passed to the program.
    #
    # @return [void]
    #
    def self.run(argv)
      argv = ARGV.new(argv) unless argv.is_a?(ARGV)
      version_flag = argv.flag?('version')
      complete_flag = argv.flag?('completion-script')
      load_plugins
      command = parse(argv)
      if root_command? && version_flag
        print_version(command.verbose?)
      elsif root_command? && complete_flag
        print_autocompletion_script
      else
        command.configure_ansi
        command.validate!
        command.run
      end

    rescue Object => exception
      if exception.is_a?(InformativeError)
        puts exception.message
        if command.verbose?
          puts
          puts(*exception.backtrace)
        end
        exit exception.exit_status
      else
        report_error(exception)
      end
    end

    # Load additional plugins via rubygems looking for files named:
    # `PLUGIN_PREFIX_plugin`.
    #
    # rubocop:disable RescueException
    def self.load_plugins
      paths = PluginsHelper.plugin_load_paths(plugin_prefix)
      paths.each do |path|
        begin
          require path
        rescue Exception => exception
          message = "\n---------------------------------------------"
          message << "\nError loading the plugin with path `#{path}`.\n"
          message << "\n#{exception.class} - #{exception.message}"
          message << "\n#{exception.backtrace.join("\n")}"
          message << "\n---------------------------------------------\n"
          puts message.ansi.yellow
        end
      end
    end
    # rubocop:enable RescueException

    # Prints the version of the command optionally including plugins.
    #
    # @param  [Boolean] include_plugins
    #         Whether the version of the found plugins should be printed.
    #
    # @return [void]
    #
    def self.print_version(include_plugins = false)
      puts version
      if include_plugins
        PluginsHelper.plugin_load_paths(plugin_prefix).each do |path|
          puts PluginsHelper.plugin_info(path)
        end
      end
    end

    # Prints an auto-completion script according to the user shell.
    #
    # @return [void]
    #
    def self.print_autocompletion_script
      puts ShellCompletionHelper.completion_template(self)
    end

    # Allows the application to perform custom error reporting, by overriding
    # this method.
    #
    # @param [Exception] exception
    #
    #   An exception that occurred while running a command through
    #   {Command.run}.
    #
    # @raise
    #
    #   By default re-raises the specified exception.
    #
    # @return [void]
    #
    def self.report_error(exception)
      raise exception
    end

    # @visibility private
    #
    # @param  [String] error_message
    #         The error message to show to the user.
    #
    # @param  [Class] help_class
    #         The class to use to raise a ‘help’ error.
    #
    # @raise  [Help]
    #
    #   Signals CLAide that a help banner for this command should be shown,
    #   with an optional error message.
    #
    # @return [void]
    #
    def self.help!(error_message = nil, help_class = Help)
      raise help_class.new(banner, error_message)
    end

    # @visibility private
    #
    # Returns the banner for the command.
    #
    # @param  [Boolean] ansi
    #         Whether the banner should use ANSI codes to prettify output.
    #
    # @param  [Class] banner_class
    #         The class to use to format help banners.
    #
    # @return [String] The banner for the command.
    #
    def self.banner(banner_class = Banner)
      banner_class.new(self).formatted_banner
    end

    #-------------------------------------------------------------------------#

    # Set to `true` if the user specifies the `--verbose` option.
    #
    # @note
    #
    #   If you want to make use of this value for your own configuration, you
    #   should check the value _after_ calling the `super` {Command#initialize}
    #   implementation.
    #
    # @return [Boolean]
    #
    #   Wether or not backtraces should be included when presenting the user an
    #   exception that includes the {InformativeError} module.
    #
    attr_accessor :verbose
    alias_method :verbose?, :verbose

    # Set to `true` if {Command.ansi_output} returns `true` and the user
    # did **not** specify the `--no-ansi` option.
    #
    # @note (see #verbose)
    #
    # @return [Boolean]
    #
    #   Whether or not to use ANSI codes to prettify output. For instance, by
    #   default {InformativeError} exception messages will be colored red and
    #   subcommands in help banners green.
    #
    attr_accessor :ansi_output
    alias_method :ansi_output?, :ansi_output

    # Subclasses should override this method to remove the arguments/options
    # they support from `argv` _before_ calling `super`.
    #
    # The `super` implementation sets the {#verbose} attribute based on whether
    # or not the `--verbose` option is specified; and the {#ansi_output}
    # attribute to `false` if {Command.ansi_output} returns `true`, but the
    # user specified the `--no-ansi` option.
    #
    # @param [ARGV, Array] argv
    #
    #   A list of (user-supplied) params that should be handled.
    #
    def initialize(argv)
      argv = ARGV.new(argv) unless argv.is_a?(ARGV)
      @verbose = argv.flag?('verbose')
      @ansi_output = argv.flag?('ansi', Command.ansi_output?)
      @argv = argv
    end

    # @return [Bool] Whether the command was invoked by an abstract command by
    #         default.
    #
    attr_accessor :invoked_as_default
    alias_method :invoked_as_default?, :invoked_as_default

    # Raises a Help exception if the `--help` option is specified, if `argv`
    # still contains remaining arguments/options by the time it reaches this
    # implementation, or when called on an ‘abstract command’.
    #
    # Subclasses should call `super` _before_ doing their own validation. This
    # way when the user specifies the `--help` flag a help banner is shown,
    # instead of possible actual validation errors.
    #
    # @raise [Help]
    #
    # @return [void]
    #
    def validate!
      help! if @argv.flag?('help')
      help! unknown_arguments_message(@argv.remainder) unless @argv.empty?
      help! if self.class.abstract_command?
    end

    # @return [void] Disables or enables ANSI support according to the default
    #         setting and to whether a preference was expressed via the
    #         argument flag.
    #
    # @note   The support is configured before running a command to allow the
    #         same process to run multiple commands with different settings.
    #         For example a process with ANSI output enabled might want to
    #         programmatically invoke another command with the output enabled.
    #
    def configure_ansi
      if ansi_output?
        load 'claide/ansi/string_mixin.rb'
      else
        load 'claide/ansi/string_mixin_disable.rb'
      end
    end

    # Returns a message for the given unknown arguments including a suggestion.
    #
    # @param  [Array<String>] The unknown arguments.
    #
    # @return [String] The message.
    #
    def unknown_arguments_message(arguments)
      unknown = arguments.first.downcase
      if unknown.start_with?('-')
        type = :option
        suggestions = self.class.options.map do |option|
          option.first.sub('--', '')
        end
      else
        type = :command
        suggestions = self.class.subcommands_for_command_lookup.map(&:command)
      end
      ValidateHelper.unknown_arguments_message(unknown, suggestions, type)
    end

    # This method should be overridden by the command class to perform its work.
    #
    # @return [void
    #
    def run
      raise 'A subclass should override the `CLAide::Command#run` method to ' \
        'actually perform some work.'
    end

    protected

    # @raise [Help]
    #
    #   Signals CLAide that a help banner for this command should be shown,
    #   with an optional error message.
    #
    # @return [void]
    #
    def help!(error_message = nil)
      if invoked_as_default?
        command = self.class.superclass
      else
        command = self.class
      end
      command.help!(error_message)
    end

    #-------------------------------------------------------------------------#
  end
end
