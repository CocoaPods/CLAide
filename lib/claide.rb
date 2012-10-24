module CLAide
  VERSION = '0.0.1'

  class Command
    class Informative < StandardError
      attr_reader :exit_status

      def initialize(message = nil, exit_status = 1)
        @exit_status = exit_status
        super(message)
      end
    end

    class Help < Informative
      attr_reader :command_class, :error_message

      def initialize(command_class, error_message = nil)
        @command_class, @error_message = command_class, error_message
        super(nil, error_message.nil? ? 0 : 1)
      end

      def message
        banner = []

        if @error_message
          banner << "[!] #{@error_message}"
        end

        if @command_class.abstract_command?
          banner << @command_class.description if @command_class.description
        elsif usage = @command_class.formatted_command_description
          banner << 'Usage:'
          banner << usage
        end

        if commands = @command_class.formatted_subcommand_summaries
          banner << 'Commands:'
          banner << commands
        end

        banner << 'Options:'
        banner << @command_class.formatted_options_description
        banner.join("\n\n")
      end
    end

    # Only available if String#demodulize, String#underscore, and
    # String#dasherize exist. For instance, when ActiveSupport is loaded
    # beforehand.
    #
    # Otherwise you will have to register the subcommands manually.
    def self.command
      unless @command
        if %w{ demodulize underscore dasherize }.all? { |m| String.method_defined?(m) }
          @command = name.demodulize.underscore.dasherize
        end
      end
      @command
    end

    def self.binname
      File.basename($0)
    end

    def self.full_command
      if superclass == Command
        "#{binname}"
      else
        "#{superclass.full_command} #{command}"
      end
    end

    def self.subcommands
      @subcommands ||= []
    end

    def self.inherited(subcommand)
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
    def self.options
      [
        ['--verbose', 'Show more debugging information'],
        ['--help',    'Show help banner'],
      ]
    end

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
    end

    def self.formatted_options_description
      key_size = options.map { |opt| opt.first.size }.max
      options.map { |key, desc| "    #{key.ljust(key_size)}   #{desc}" }.join("\n")
    end

    def self.formatted_command_summary_or_description(message, include_arguments)
      if message
        message = message.strip_heredoc if message.respond_to?(:strip_heredoc)
        message = message.split("\n").map { |line| "      #{line}" }.join("\n")
        "    $ #{full_command}#{ " #{arguments}" if include_arguments && arguments}\n\n#{message}"
      end
    end

    def self.formatted_command_description
      formatted_command_summary_or_description(description || summary, true)
    end

    def self.formatted_subcommand_summaries
      subcommands = self.subcommands.reject { |subcommand| subcommand.summary.nil? }.sort_by(&:command)
      unless subcommands.empty?
        command_size = subcommands.map { |subcommand| subcommand.command.size }.max
        subcommands.map do |subcommand|
          "    * #{subcommand.command.ljust(command_size)}   #{subcommand.summary}"
        end.join("\n")
      end
    end

    def self.parse(argv)
      argv = ARGV.new(argv) unless argv.is_a?(ARGV)
      command = argv.arguments.first
      if command && subcommand = subcommands.find { |sc| sc.command == command }
        argv.shift_argument
        subcommand.parse(argv)
      else
        new(argv)
      end
    end

    def self.run(argv)
      command = parse(argv)
      command.validate!
      command.run
    rescue Exception => exception
      if exception.is_a?(Informative)
        puts exception.message
        if command.verbose?
          puts
          puts *exception.backtrace
        end
        exit(exception.respond_to?(:exit_status) ? exception.exit_status : 1)
      else
        report_error(exception)
      end
    end

    # TODO
    def self.report_error(exception)
      raise exception
    end

    attr_accessor :verbose
    alias_method :verbose?, :verbose

    # Sets the `verbose` attribute based on wether or not the `--verbose`
    # option is specified.
    #
    # Subclasses should override this method to remove the arguments/options
    # they support from argv before calling `super`.
    def initialize(argv)
      @verbose = argv.flag?('verbose')
      @argv = argv
    end

    # Raises a Help exception if the `--help` option is specified, if argv
    # still contains remaining arguments/options by the time it reaches this
    # implementation, or when called on an ‘abstract command’.
    def validate!
      help! if @argv.flag?('help')
      remainder = @argv.remainder
      help! "Unknown arguments: #{remainder.join(' ')}" unless remainder.empty?
      help! if self.class.abstract_command?
    end

    # This method should be overriden by command classes to perform their work.
    def run
      raise "A subclass should override the Command#run method to actually perform some work."
    end

    protected

    def help!(error_message = nil)
      raise Help.new(self.class, error_message)
    end
  end

  class ARGV
    def initialize(argv)
      @entries = self.class.parse(argv)
    end

    def remainder
      @entries.map do |type, (key, value)|
        case type
        when :arg
          key
        when :flag
          "--#{'no-' if value == false}#{key}"
        when :option
          ["--#{key}", value]
        end
      end.flatten
    end

    def options
      options = {}
      @entries.each do |type, (key, value)|
        options[key] = value unless type == :arg
      end
      options
    end

    def arguments
      @entries.map { |type, value| value if type == :arg }.compact
    end

    def arguments!
      arguments = []
      while arg = shift_argument
        arguments << arg
      end
      arguments
    end

    def flag?(name, default = nil)
      result = delete_entry(:flag, name)
      result.nil? ? default : result
    end

    def option(name)
      delete_entry(:option, name)
    end

    def shift_argument
      if entry = @entries.find { |type, _| type == :arg }
        @entries.delete(entry)
        entry.last
      end
    end

    private

    def delete_entry(requested_type, requested_key)
      result = nil
      @entries.delete_if do |type, (key, value)|
        if requested_key == key && requested_type == type
          result = value
          true
        end
      end
      result
    end

    def self.parse(argv)
      entries = []
      copy = argv.dup
      while x = copy.shift
        type = key = value = nil
        if is_arg?(x)
          # A regular argument (e.g. a command)
          type, value = :arg, x
        else
          key = x[2..-1]
          if (next_x = copy.first) && is_arg?(next_x)
            # An option with a value
            type = :option
            value = copy.shift
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
end

