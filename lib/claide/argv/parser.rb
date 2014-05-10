module CLAide
  class ARGV
    module Parser
      # @return [Array<Array<Symbol, String, Array>>] A list of tuples for each
      #         parameter, where the first entry is the `type` and the second
      #         entry the actual parsed parameter.
      #
      # @example
      #
      #   list = parse(['tea', '--no-milk', '--sweetner=honey'])
      #   list # => [[:arg, "tea"],
      #              [:flag, ["milk", false]],
      #              [:option, ["sweetner", "honey"]]]
      #
      def self.parse(argv)
        entries = []
        copy = argv.map(&:to_s)
        while argument = copy.shift
          type = argument_type(argument)
          parameter = argument_parameter(type, argument)
          entries << [type, parameter]
        end
        entries
      end

      # @return [Symbol] Returns the type of an argument. The types can be
      #         either: `:arg`, `:flag`, `:option`.
      #
      # @param  [String] argument
      #         The argument to check.
      #
      def self.argument_type(argument)
        if argument.start_with?('--')
          if argument.include?('=')
            :option
          else
            :flag
          end
        else
          :arg
        end
      end

      # @return [String, Array<String, String>] Returns argument itself for
      #         normal arguments (like commands) and a tuple with they key and
      #         the value for options and flags.
      #
      # @param  [String] argument
      #         The argument to check.
      #
      def self.argument_parameter(type, argument)
        case type
        when :arg
          return argument
        when :flag
          if argument.start_with?('--no-')
            key = argument[5..-1]
            value = false
          else
            key = argument[2..-1]
            value = true
          end
          return [key, value]
        when :option
          key, value = argument[2..-1].split('=', 2)
          return [key, value]
        end
      end
    end
  end
end
