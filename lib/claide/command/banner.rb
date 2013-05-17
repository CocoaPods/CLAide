module CLAide
  class Command

    # Creates the formatted banner to present as help of the provided command
    # class.
    #
    class Banner

      # @return [Class]
      #
      attr_accessor :command

      # @return [Bool]
      #
      attr_accessor :colorize_output
      alias_method :colorize_output?, :colorize_output

      # @param [Class] command @see command
      # @param [Class] colorize_output@see colorize_output
      #
      def initialize(command, colorize_output = false)
        @command = command
        @colorize_output = colorize_output
      end

      # @return [String]
      #
      def formatted_banner
        banner = []
        if command.abstract_command?
          banner << command.description if command.description
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

      private

      # @!group Banner sections

      #-----------------------------------------------------------------------#

      # @return [String]
      #
      def formatted_options_description
        opts = command.options
        size = opts.map { |opt| opt.first.size }.max
        opts.map { |key, desc| "    #{key.ljust(size)}   #{desc}" }.join("\n")
      end

      # @return [String]
      #
      def formatted_usage_description
        if message = command.description || command.summary
          message = strip_heredoc(message)
          message = message.split("\n").map { |line| "      #{line}" }.join("\n")
          args = " #{command.arguments}" if command.arguments
          "    $ #{command.full_command}#{args}\n\n#{message}"
        end
      end

      # @return [String]
      #
      def formatted_subcommand_summaries
        subcommands = command.subcommands.reject do |subcommand|
          subcommand.summary.nil?
        end.sort_by(&:command)
        unless subcommands.empty?
          command_size = subcommands.map { |cmd| cmd.command.size }.max
          subcommands.map do |subcommand|
            subcommand_string = subcommand.command.ljust(command_size)
            subcommand_string = subcommand_string.green if colorize_output?
            is_default = subcommand.command == command.default_subcommand
            if is_default
              bullet_point = '-'
            else
              bullet_point = '*'
            end
            "    #{bullet_point} #{subcommand_string}   #{subcommand.summary}"
          end.join("\n")
        end
      end

      private

      # @!group Private helpers

      #-----------------------------------------------------------------------#

      # @return [String] Lifted straight from ActiveSupport. Thanks guys!
      #
      def strip_heredoc(string)
        if min = string.scan(/^[ \t]*(?=\S)/).min
          string.gsub(/^[ \t]{#{min.size}}/, '')
        else
          string
        end
      end

    end
  end
end
