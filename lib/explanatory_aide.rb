module ExplanatoryAide
  class Command
    class Informative < StandardError; end
    class Help < Informative
      def initialize(command_class, argv, unrecognized_command = nil)
        @command_class, @argv, @unrecognized_command = command_class, argv, unrecognized_command
      end

      def subcommands
        @command_class.formatted_subcommands_description
      end

      def options
        @command_class.formatted_options_description
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

    def self.full_command
      if superclass.superclass == Command
        command
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

    def self.options
      []
    end

    def self.description
      "Here goes a description of the subcommand: #{command}"
    end

    def self.formatted_options_description
      key_size = options.inject(0) { |size, (key, _)| key.size > size ? key.size : size }
      options.map { |key, desc| "    #{key.ljust(key_size)}   #{desc}" }.join("\n")
    end

    def self.formatted_subcommands_description
      subcommands.sort_by(&:command).map do |klass|
        description = klass.description.split("\n").map { |line| line.ljust(6) }.join("\n")
        "    $ #{klass.full_command}\n\n      #{description}"
      end.join("\n\n")
    end

    def self.parse(argv)
      argv = ARGV.new(argv) unless argv.is_a?(ARGV)
      command = argv.arguments.first
      if subcommand = subcommands.find { |sc| sc.command == command }
        argv.shift_argument
        subcommand.parse(argv)
      else
        new(argv)
      end
    end

    def self.run(argv)
      parse(argv).run
    end

    def initialize(argv)
      raise Help.new(self.class, argv) unless argv.remainder.empty?
      @argv = argv
    end

    # This method should *only* be overriden by command classes that actually
    # perform any work. This ensures that commands that require a subcommand
    # will show the help banner instead.
    def run
      raise Help.new(self.class, @argv)
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

    def flag?(name)
      delete_entry(:flag, name)
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
