# encoding: utf-8

module CLAide
  class Command
    module ValidateHelper
      # Returns a message for the given unknown arguments including a suggestion.
      #
      # @param  [Array<String>] The unknown arguments.
      #
      # @return [String] The message.
      #
      def self.unknown_arguments_message(unknown, suggestions, type, ansi_output = false)
        sorted = suggestions.sort_by do |suggestion|
          levenshtein_distance(suggestion, unknown)
        end
        suggestion = sorted.first
        pretty_suggestion = prettify_validation_suggestion(suggestion, type, ansi_output)
        "Unknown #{type}: `#{unknown}`\n" \
          "Did you mean: #{pretty_suggestion}"
      end

      # Prettifies the given validation suggestion according to the type.
      #
      # @param  [String] suggestion
      #         The suggestion to prettify.
      #
      # @param  [Type]
      #         The type of the suggestion: either `:command` or `:option`.
      #
      # @return [String] A handsome suggestion.
      #
      def self.prettify_validation_suggestion(suggestion, type, ansi_output)
        if type == :option
          suggestion = "--#{suggestion}"
        end
        return suggestion unless ansi_output
        case type
        when :option
          suggestion.blue
        when :command
          suggestion.green
        else
          suggestion.red
        end
      end

      # Returns the Levenshtein distance between the given strings.
      # From: http://rosettacode.org/wiki/Levenshtein_distance#Ruby
      #
      # @param  [String] a
      #         The first string to compare.
      #
      # @param  [String] b
      #         The second string to compare.
      #
      # @return [Fixnum] The distance between the strings.
      #
      def self.levenshtein_distance(a, b)
        a, b = a.downcase, b.downcase
        costs = Array(0..b.length)
        (1..a.length).each do |i|
          costs[0], nw = i, i - 1
          (1..b.length).each do |j|
            costs[j], nw = [costs[j] + 1, costs[j - 1] + 1, a[i - 1] == b[j - 1] ? nw : nw + 1].min, costs[j]
          end
        end
        costs[b.length]
      end
    end
  end
end
