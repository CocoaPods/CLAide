module ExplanatoryAide
  class Command
    class Informative < StandardError; end
    class Help < Informative
      def initialize(command_class, argv, unrecognized_command = nil)
        @command_class, @argv, @unrecognized_command = command_class, argv, unrecognized_command
      end
    end

    def self.subcommands
      @subcommands ||= {}
    end

    if %w{ demodulize underscore dasherize }.all? { |m| String.method_defined?(m) }
      # Only available if String#demodulize, String#underscore, and
      # String#dasherize exist. For instance, when ActiveSupport is loaded
      # beforehand.
      #
      # Otherwise you will have to register the subcommands manually.
      def self.inherited(subcommand)
        subcommands[subcommand.name.demodulize.underscore.dasherize] = subcommand
      end
    end

    def self.run(argv)
      argv = ARGV.new(argv) unless argv.is_a?(ARGV)
      if subcommand = subcommands[argv.arguments.first]
        argv.shift_argument
        subcommand.run(argv)
      else
        new(argv)
      end
    end

    def initialize(argv)
      raise Help.new(self.class, argv) unless argv.remainder.empty?
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
      i = 0
      while x = copy.shift
        start, i = i, i+1
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
            i += 1
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
