# encoding: utf-8

module CLAide
  class Command
    class ArgumentSuggester
      # @param  [String] argument
      #         The unrecognized argument for which to make a suggestion.
      #
      # @param  [Class] command_class
      #         The class of the command which encountered the unrecognized
      #         arguments.
      #
      def initialize(argument, command_class)
        @argument, @command_class = argument, command_class
        @argument_type = ARGV::Parser.argument_type(@argument)
      end

      # @return [Array<String>] The list of the valid arguments for a command
      #         according to the type of the argument.
      #
      def possibilities
        case @argument_type
        when :option, :flag
          @command_class.options.map(&:first)
        when :arg
          @command_class.subcommands_for_command_lookup.map(&:command)
        end
      end

      # @return [String] Returns a suggested argument from `possibilities` based
      #         on the `levenshtein_distance` score.
      #
      def suggested_argument
        result = possibilities.sort_by do |element|
          self.class.levenshtein_distance(@argument, element)
        end.first

        result = result.first if result.is_a?(Array)
        result
      end

      # @return [String] Returns a message including a suggestion for the given
      #         suggestion.
      #
      def suggestion
        argument_description = @argument_type == :arg ? 'command' : 'option'
        if suggestion = suggested_argument
          pretty_suggestion = self.class.prettify_suggestion(suggestion,
                                                             @argument_type)
          "Unknown #{argument_description}: `#{@argument}`\n" \
            "Did you mean: #{pretty_suggestion}"
        else
          "Unknown #{argument_description}: `#{@argument}`"
        end
      end

      # Prettifies the given validation suggestion according to the type.
      #
      # @param  [String] suggestion
      #         The suggestion to prettify.
      #
      # @param  [Type] argument_type
      #         The type of the suggestion: either `:command` or `:option`.
      #
      # @return [String] A handsome suggestion.
      #
      def self.prettify_suggestion(suggestion, argument_type)
        case argument_type
        when :option, :flag
          suggestion = "#{suggestion}"
          suggestion.ansi.blue
        when :arg
          suggestion.ansi.green
        end
      end

      # Returns the Levenshtein distance between the given strings.
      # From: http://rosettacode.org/wiki/Levenshtein_distance#Ruby
      #
      # @param  [String] a
      #         The first dataset to compare.
      #
      # @param  [String] b
      #         The second string to compare.
      #
      # @return [Fixnum] The distance between the strings.
      #
      # rubocop:disable all
      def self.levenshtein_distance(a, b)
        a, b = Array(a), Array(b)
        results = []

        a.each do |c|
          b.each do |d|
            c, d = c.downcase, d.downcase
            costs = Array(0..d.length)
            (1..c.length).each do |i|
              costs[0], nw = i, i - 1
              (1..d.length).each do |j|
                costs[j], nw = [
                  costs[j] + 1, costs[j - 1] + 1, c[i - 1] == d[j - 1] ? nw : nw + 1
                ].min, costs[j]
              end
            end
            results << costs[d.length]
          end
        end

        results[results.each_with_index.max[1]]
      end
      # rubocop:enable all
    end
  end
end
