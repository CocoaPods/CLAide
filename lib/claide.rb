module CLAide
  VERSION = '0.0.1'

  # This class is responsible for parsing the parameters specified by the user,
  # accessing individual parameters, and keep state by removing handled
  # parameters.
  #
  class ARGV

    # @param [Array<String>] argv
    #
    #   A list of parameters. Each entry is ensured to be a string by calling
    #   `#to_s` on it.
    #
    def initialize(argv)
      @entries = self.class.parse(argv)
    end

    # @return [Array<String>]
    #
    #   A list of the remaining unhandled parameters, in the same format a user
    #   specifies it in.
    #
    # @example
    #
    #   argv = CLAide::ARGV.new(['tea', '--no-milk', '--sweetner=honey'])
    #   argv.shift_argument # => 'tea'
    #   argv.remainder      # => ['--no-milk', '--sweetner=honey']
    #
    def remainder
      @entries.map do |type, (key, value)|
        case type
        when :arg
          key
        when :flag
          "--#{'no-' if value == false}#{key}"
        when :option
          "--#{key}=#{value}"
        end
      end
    end

    # @return [Hash]
    #
    #   A hash that consists of the remaining flags and options and their
    #   values.
    #
    # @example
    #
    #   argv = CLAide::ARGV.new(['tea', '--no-milk', '--sweetner=honey'])
    #   argv.options # => { 'milk' => false, 'sweetner' => 'honey' }
    #
    def options
      options = {}
      @entries.each do |type, (key, value)|
        options[key] = value unless type == :arg
      end
      options
    end

    # @return [Array<String>]
    #
    #   A list of the remaining arguments.
    #
    # @example
    #
    #   argv = CLAide::ARGV.new(['tea', 'white', '--no-milk', 'biscuit'])
    #   argv.shift_argument # => 'tea'
    #   argv.arguments      # => ['white', 'biscuit']
    #
    def arguments
      @entries.map { |type, value| value if type == :arg }.compact
    end

    # @return [Array<String>]
    #
    #   A list of the remaining arguments.
    #
    # @note
    #
    #   This version also removes the arguments from the remaining parameters.
    #
    # @example
    #
    #   argv = CLAide::ARGV.new(['tea', 'white', '--no-milk', 'biscuit'])
    #   argv.arguments  # => ['tea', 'white', 'biscuit']
    #   argv.arguments! # => ['tea', 'white', 'biscuit']
    #   argv.arguments  # => []
    #
    def arguments!
      arguments = []
      while arg = shift_argument
        arguments << arg
      end
      arguments
    end

    # @return [String]
    #
    #   The first argument in the remaining parameters.
    #
    # @note
    #
    #   This will remove the argument from the remaining parameters.
    #
    # @example
    #
    #   argv = CLAide::ARGV.new(['tea', 'white'])
    #   argv.shift_argument # => 'tea'
    #   argv.arguments      # => ['white']
    #
    def shift_argument
      if entry = @entries.find { |type, _| type == :arg }
        @entries.delete(entry)
        entry.last
      end
    end

    # @return [Boolean, nil]
    #
    #   Returns `true` if the flag by the specified `name` is among the
    #   remaining parameters and is not negated.
    #
    # @param [String] name
    #
    #   The name of the flag to look for among the remaining parameters.
    #
    # @param [Boolean] default
    #
    #   The value that is returned in case the flag is not among the remaining
    #   parameters.
    #
    # @note
    #
    #   This will remove the flag from the remaining parameters.
    #
    # @example
    #
    #   argv = CLAide::ARGV.new(['tea', '--no-milk', '--sweetner=honey'])
    #   argv.flag?('milk')       # => false
    #   argv.flag?('milk')       # => nil
    #   argv.flag?('milk', true) # => true
    #   argv.remainder           # => ['tea', '--sweetner=honey']
    #
    def flag?(name, default = nil)
      delete_entry(:flag, name, default)
    end

    # @return [String, nil]
    #
    #   Returns the value of the option by the specified `name` is among the
    #   remaining parameters.
    #
    # @param [String] name
    #
    #   The name of the option to look for among the remaining parameters.
    #
    # @param [String] default
    #
    #   The value that is returned in case the option is not among the
    #   remaining parameters.
    #
    # @note
    #
    #   This will remove the option from the remaining parameters.
    #
    # @example
    #
    #   argv = CLAide::ARGV.new(['tea', '--no-milk', '--sweetner=honey'])
    #   argv.option('sweetner')          # => 'honey'
    #   argv.option('sweetner')          # => nil
    #   argv.option('sweetner', 'sugar') # => 'sugar'
    #   argv.remainder                   # => ['tea', '--no-milk']
    #
    def option(name, default = nil)
      delete_entry(:option, name, default)
    end

    private

    def delete_entry(requested_type, requested_key, default)
      result = nil
      @entries.delete_if do |type, (key, value)|
        if requested_key == key && requested_type == type
          result = value
          true
        end
      end
      result.nil? ? default : result
    end

    def self.parse(argv)
      entries = []
      copy = argv.map(&:to_s)
      while x = copy.shift
        type = key = value = nil
        if is_arg?(x)
          # A regular argument (e.g. a command)
          type, value = :arg, x
        else
          key = x[2..-1]
          if key.include?('=')
            # An option with a value
            type = :option
            key, value = key.split('=', 2)
          else
            # A boolean flag
            type = :flag
            value = true
            if key[0,3] == 'no-'
              # A negated boolean flag
              key = key[3..-1]
              value = false
            end
          end
          value = [key, value]
        end
        entries << [type, value]
      end
      entries
    end

    def self.is_arg?(x)
      x[0,2] != '--'
    end
  end

  # Including this module into an exception class will ensure that when raised,
  # while running {Command.run}, only the message of the exception will be
  # shown to the user. Unless disabled with the `--verbose` flag.
  #
  # In addition, the message will be colored red, if {Command.colorize_output}
  # is set to `true`.
  #
  module InformativeError
    attr_writer :exit_status

    # @return [Numeric]
    #
    #   The exist status code that should be used to terminate the program with.
    #
    #   Defaults to `1`.
    #
    def exit_status
      @exit_status ||= 1
    end
  end

  # The exception class that is raised to indicate a help banner should be
  # shown while running {Command.run}.
  #
  class Help < StandardError
    include InformativeError

    # @return [Command]
    #
    #   The command instance for which a help banner should be shown.
    #
    attr_reader :command

    # @return [String]
    #
    #   The optional error message that will be shown before the help banner.
    #
    attr_reader :error_message

    # @param [Command] command
    #
    #   An instance of a command class for which a help banner should be shown.
    #
    # @param [String] error_message
    #
    #   An optional error message that will be shown before the help banner.
    #   If specified, the exit status, used to terminate the program with, will
    #   be set to `1`, otherwise a {Help} exception is treated as not being a
    #   real error and exits with `0`.
    #
    def initialize(command, error_message = nil)
      @command, @error_message = command, error_message
      @exit_status = @error_message.nil? ? 0 : 1
    end

    # @return [String]
    #
    #   The optional error message, colored in red if {Command.colorize_output}
    #   is set to `true`.
    #
    def formatted_error_message
      if @error_message
        message = "[!] #{@error_message}"
        @command.colorize_output? ? message.red : message
      end
    end

    # @return [String]
    #
    #   The optional error message, combined with the help banner of the
    #   command.
    #
    def message
      [formatted_error_message, @command.formatted_banner].compact.join("\n\n")
    end
  end

  class Command
    class << self
      attr_accessor :abstract_command
      alias_method :abstract_command?, :abstract_command

      attr_accessor :summary

      # Should be set by the subclass to provide a description for the command.
      #
      # If this returns `nil` it will not be included in the help banner.
      attr_accessor :description

      # Should be set by the subclass to a list of arguments the command takes.
      #
      # If this returns `nil` it will not be included in the help banner.
      attr_accessor :arguments

      attr_writer :colorize_output
      def colorize_output
        if @colorize_output.nil?
          @colorize_output = String.method_defined?(:red) &&
                               String.method_defined?(:green)
        end
        @colorize_output
      end
      alias_method :colorize_output?, :colorize_output

      attr_writer :command

      # @returns [String]  A snake-cased version of the class’ name, unless
      #                    explicitely assigned.
      def command
        @command ||= name.split('::').last.gsub(/[A-Z]+[a-z]*/) do |part|
          part.downcase << '-'
        end[0..-2]
      end

      def full_command
        if superclass == Command
          "#{command}"
        else
          "#{superclass.full_command} #{command}"
        end
      end

      def subcommands
        @subcommands ||= []
      end

      def inherited(subcommand)
        subcommands << subcommand
      end

      # Should be overriden by a subclass if it handles any options.
      #
      # The subclass has to combine the result of calling `super` and its own
      # list of options. The recommended way of doing this is by concatenating
      # concatening to this classes’ own options.
      #
      # @example
      #
      #   def self.options
      #     [
      #       ['--verbose', 'Print more info'],
      #       ['--help',    'Print help banner'],
      #     ].concat(super)
      #   end
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

      def parse(argv)
        argv = ARGV.new(argv) unless argv.is_a?(ARGV)
        cmd = argv.arguments.first
        if cmd && subcommand = subcommands.find { |sc| sc.command == cmd }
          argv.shift_argument
          subcommand.parse(argv)
        else
          new(argv)
        end
      end

      def run(argv)
        command = parse(argv)
        command.validate!
        command.run
      rescue Exception => exception
        if exception.is_a?(InformativeError)
          puts exception.message
          if command.verbose?
            puts
            puts *exception.backtrace
          end
          exit exception.exit_status
        else
          report_error(exception)
        end
      end

      # TODO
      def report_error(exception)
        raise exception
      end
    end

    attr_accessor :verbose
    alias_method :verbose?, :verbose

    attr_accessor :colorize_output
    alias_method :colorize_output?, :colorize_output

    # Sets the `verbose` attribute based on wether or not the `--verbose`
    # option is specified.
    #
    # Subclasses should override this method to remove the arguments/options
    # they support from argv _before_ calling `super`.
    def initialize(argv)
      @verbose = argv.flag?('verbose')
      @colorize_output = argv.flag?('color', Command.colorize_output?)
      @argv = argv
    end

    # Raises a Help exception if the `--help` option is specified, if argv
    # still contains remaining arguments/options by the time it reaches this
    # implementation, or when called on an ‘abstract command’.
    #
    # Subclasses should call `super` _before_ doing their own validation. This
    # way when the user specifies the `--help` flag a help banner is shown,
    # instead of possible actual validation errors.
    def validate!
      help! if @argv.flag?('help')
      remainder = @argv.remainder
      help! "Unknown arguments: #{remainder.join(' ')}" unless remainder.empty?
      help! if self.class.abstract_command?
    end

    # This method should be overriden by command classes to perform their work.
    def run
      raise "A subclass should override the Command#run method to actually " \
            "perform some work."
    end

    def formatted_options_description
      opts = self.class.options
      size = opts.map { |opt| opt.first.size }.max
      opts.map { |key, desc| "    #{key.ljust(size)}   #{desc}" }.join("\n")
    end

    def formatted_usage_description
      if message = self.class.description || self.class.summary
        message = message.strip_heredoc if message.respond_to?(:strip_heredoc)
        message = message.split("\n").map { |line| "      #{line}" }.join("\n")
        args = " #{self.class.arguments}" if self.class.arguments
        "    $ #{self.class.full_command}#{args}\n\n#{message}"
      end
    end

    def formatted_subcommand_summaries
      subcommands = self.class.subcommands.reject do |subcommand|
        subcommand.summary.nil?
      end.sort_by(&:command)
      unless subcommands.empty?
        command_size = subcommands.map { |cmd| cmd.command.size }.max
        subcommands.map do |subcommand|
          command = subcommand.command.ljust(command_size)
          command = command.green if colorize_output?
          "    * #{command}   #{subcommand.summary}"
        end.join("\n")
      end
    end

    def formatted_banner
      banner = []
      if self.class.abstract_command?
        banner << self.class.description if self.class.description
      elsif usage = formatted_usage_description
        banner << 'Usage:'
        banner << usage
      end
      if commands = formatted_subcommand_summaries
        banner << 'Commands:'
        banner << commands
      end
      banner << 'Options:'
      banner << formatted_options_description
      banner.join("\n\n")
    end

    protected

    def help!(error_message = nil)
      raise Help.new(self, error_message)
    end
  end

end
