# encoding: utf-8

module CLAide
  class Command
    module ValidationHelper
      # Returns a message for the given unknown arguments including a
      # suggestion.
      #
      # @param  [Array<String>] The unknown arguments.
      #
      # @return [String] The message.
      #
      def self.unknown_arguments_message(unknown, suggestions, type)
        sorted = suggestions.sort_by do |suggestion|
          Helper.levenshtein_distance(suggestion, unknown)
        end
        suggestion = sorted.first
        pretty_suggestion = prettify_validation_suggestion(suggestion, type)
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
      def self.prettify_validation_suggestion(suggestion, type)
        if type == :option
          suggestion = "--#{suggestion}"
          suggestion.ansi.blue
        else
          suggestion.ansi.green
        end
      end
    end
  end
end
