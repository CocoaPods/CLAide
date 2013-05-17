require 'claide/command/banner'

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

    #-------------------------------------------------------------------------#

    class << self

      # @return [Boolean] Indicates whether or not this command can actually
      #         perform work of itself, or that it only contains subcommands.
      #
      attr_accessor :abstract_command
      alias_method :abstract_command?, :abstract_command

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

      # @return [String] A list of arguments the command handles. This is shown
      #         in the usage section of the command’s help banner.
      #
      attr_accessor :arguments

      # @return [Boolean] The default value for {Command#colorize_output}. This
      #         defaults to `true` if `String` has the instance methods
      #         `#green` and `#red`.  Which are defined by, for instance, the
      #         [colored](https://github.com/defunkt/colored) gem.
      #
      def colorize_output
        if @colorize_output.nil?
          @colorize_output = String.method_defined?(:red) &&
                               String.method_defined?(:green)
        end
        @colorize_output
      end
      attr_writer :colorize_output
      alias_method :colorize_output?, :colorize_output

      # @return [String] The name of the command. Defaults to a snake-cased
      #         version of the class’ name.
      #
      def command
        @command ||= name.split('::').last.gsub(/[A-Z]+[a-z]*/) do |part|
          part.downcase << '-'
        end[0..-2]
      end
      attr_writer :command

      # @return [String] The full command up-to this command.
      #
      # @example
      #
      #   BevarageMaker::Tea.full_command # => "beverage-maker tea"
      #
      def full_command
        if superclass == Command
          "#{command}"
        else
          "#{superclass.full_command} #{command}"
        end
      end

      # @return [Array<Class>] A list of command classes that are nested under
      #         this command.
      #
      def subcommands
        @subcommands ||= []
      end

      # @visibility private
      #
      # Automatically registers a subclass as a subcommand.
      #
      def inherited(subcommand)
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
      def options
        options = [
          ['--verbose', 'Show more debugging information'],
          ['--help',    'Show help banner of specified command'],
        ]
        if Command.colorize_output?
          options.unshift(['--no-color', 'Show output without color'])
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
      def parse(argv)
        argv = ARGV.new(argv) unless argv.is_a?(ARGV)
        cmd = argv.arguments.first
        if cmd && subcommand = subcommands.find { |sc| sc.command == cmd }
          argv.shift_argument
          subcommand.parse(argv)
        elsif abstract_command? && default_subcommand
          subcommand = subcommands.find { |sc| sc.command == default_subcommand }
          unless subcommand
            raise "Unable to find the default subcommand `#{default_subcommand}` " \
              "for command `#{self}`."
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
      def run(argv)
        command = parse(argv)
        command.validate!
        command.run
        rescue Exception => exception
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
      def report_error(exception)
        raise exception
      end

      # @visibility private
      #
      # @raise [Help]
      #
      #   Signals CLAide that a help banner for this command should be shown,
      #   with an optional error message.
      #
      # @return [void]
      #
      def help!(error_message = nil, colorize = false)
        raise Help.new(banner(colorize), error_message, colorize)
      end

      # @visibility private
      #
      # Returns the banner for the command.
      #
      # @param  [Bool] colorize
      #         Whether the banner should be returned colorized.
      #
      # @return [String] The banner for the command.
      #
      def banner(colorize = false)
        Banner.new(self, colorize).formatted_banner
      end

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

    # Set to `true` if {Command.colorize_output} returns `true` and the user
    # did **not** specify the `--no-color` option.
    #
    # @note (see #verbose)
    #
    # @return [Boolean]
    #
    #   Wether or not to color {InformativeError} exception messages red and
    #   subcommands in help banners green.
    #
    attr_accessor :colorize_output
    alias_method :colorize_output?, :colorize_output

    # @return [Bool] Whether the command was invoked by an abstract command by
    #         default.
    #
    attr_accessor :invoked_as_default
    alias_method :invoked_as_default?, :invoked_as_default

    # Subclasses should override this method to remove the arguments/options
    # they support from `argv` _before_ calling `super`.
    #
    # The `super` implementation sets the {#verbose} attribute based on whether
    # or not the `--verbose` option is specified; and the {#colorize_output}
    # attribute to `false` if {Command.colorize_output} returns `true`, but the
    # user specified the `--no-color` option.
    #
    # @param [ARGV, Array] argv
    #
    #   A list of (user-supplied) params that should be handled.
    #
    def initialize(argv)
      argv = ARGV.new(argv) unless argv.is_a?(ARGV)
      @verbose = argv.flag?('verbose')
      @colorize_output = argv.flag?('color', Command.colorize_output?)
      @argv = argv
    end

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
      help! "Unknown arguments: #{@argv.remainder.join(' ')}" if !@argv.empty?
      help! if self.class.abstract_command?
    end

    # This method should be overridden by the command class to perform its work.
    #
    # @return [void
    #
    def run
      raise "A subclass should override the Command#run method to actually " \
            "perform some work."
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
      command = command.help!(error_message, colorize_output?)
    end

    #-------------------------------------------------------------------------#

  end
end
