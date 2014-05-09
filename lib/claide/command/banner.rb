# encoding: utf-8

module CLAide
  class Command
    # Creates the formatted banner to present as help of the provided command
    # class.
    #
    class Banner
      # @return [Class] The command for which the banner should be created.
      #
      attr_accessor :command

      # @param [Class] command @see command
      #
      def initialize(command)
        @command = command
      end

      # @return [String] The banner for the command.
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

      # @return [String] The section describing the usage of the command.
      #
      def formatted_usage_description
        if message = command.description || command.summary
          message_lines = strip_heredoc(message).split("\n")
          message_lines = message_lines.map { |l| l.insert(0, ' ' * 6) }
          formatted_message = message_lines.join("\n")

          signature = prettify_signature(command)
          "$ #{signature}\n\n#{formatted_message}".insert(0, ' ' * 4)
        end
      end

      # @return [String] The indentation of the subcommands and of the options
      #         names.
      #
      NAME_INDENTATION = 4

      # @return [String] The minimum between a name and its description.
      #
      DESCRIPTION_SPACES = 3

      # @return [String] The section describing the subcommands of the command.
      #
      def formatted_subcommand_summaries
        subcommands = subcommands_for_banner
        unless subcommands.empty?
          command_size = subcommands.map { |cmd| cmd.command.size }.max
          subcommands.map do |subcommand|
            subcommand_summary(subcommand, command_size)
          end.join("\n")
        end
      end

      # @return [String] The line describing a single subcommand.
      #
      def subcommand_summary(subcommand, command_size)
        subcommand_string = subcommand.command.ljust(command_size)
        subcommand_string = prettify_subcommand(subcommand_string)
        is_default = subcommand.command == command.default_subcommand
        if is_default
          bullet_point = '>'
        else
          bullet_point = '*'
        end
        "    #{bullet_point} #{subcommand_string}   #{subcommand.summary}"
      end

      # @return [String] The section describing the options of the command.
      #
      def formatted_options_description
        options = command.options
        max_key_size = options.map { |option| option.first.size }.max
        options.map do |name, description|
          option_description(name, description, max_key_size)
        end.join("\n")
      end

      # @return [String] The line describing a single option.
      #
      def option_description(name, description, max_name_width)
        result = prettify_option_name(name).ljust(max_name_width)
        result.insert(0, ' ' * NAME_INDENTATION)
        result.insert(-1, ' ' * DESCRIPTION_SPACES)
        desc_start = max_name_width + NAME_INDENTATION + DESCRIPTION_SPACES
        result << wrap_with_indent(description, desc_start)
      end

      # @!group Subclasses overrides
      #-----------------------------------------------------------------------#

      # @return [String] A decorated textual representation of the option name.
      #
      #
      def prettify_option_name(name)
        name.ansi.blue
      end

      # @return [String] A decorated textual representation of the command.
      #
      def prettify_signature(command)
        result = "#{command.full_command.ansi.green}"
        result << " #{command.arguments.ansi.magenta}" if command.arguments
        result
      end

      # @return [String] A decorated textual representation of the subcommand
      #         name.
      #
      def prettify_subcommand(name)
        name.ansi.green
      end

      # @!group Private helpers
      #-----------------------------------------------------------------------#

      # @return [String]
      #
      def subcommands_for_banner
        command.subcommands_for_command_lookup.reject do |subcommand|
          subcommand.summary.nil?
        end.sort_by(&:command)
      end

      # @return [String] Lifted straight from ActiveSupport. Thanks guys!
      #
      def strip_heredoc(string)
        if min = string.scan(/^[ \t]*(?=\S)/).min
          string.gsub(/^[ \t]{#{min.size}}/, '')
        else
          string
        end
      end

      # @return [String] Wraps a string to the terminal width taking into
      #         account the given indentation.
      #
      # @param  [String] string
      #         The string to indent.
      #
      # @param  [Fixnum] indent
      #         The number of spaces to insert before the string.
      #
      def wrap_with_indent(string, indent)
        if terminal_width == 0
          string
        else
          width = terminal_width - indent
          space = ' ' * indent
          word_wrap(string, width).split("\n").join("\n#{space}")
        end
      end

      # @return [String] Lifted straight from ActionView. Thanks guys!
      #
      def word_wrap(line, line_width)
        line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip
      end

      # @return [Fixnum] The width of the current terminal, unless being piped.
      #
      def terminal_width
        @terminal_width ||= begin
          if STDOUT.tty? && system('which tput > /dev/null 2>&1')
            `tput cols`.to_i
          else
            0
          end
        end
      end
    end
  end
end
