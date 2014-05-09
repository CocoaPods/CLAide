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

      # @return [String] The minimum between a name and its description.
      #
      SUBCOMMAND_BULLET_SIZE = 2

      # @return [String] The section describing the subcommands of the command.
      #
      def formatted_subcommand_summaries
        subcommands = subcommands_for_banner
        unless subcommands.empty?
          subcommands.map do |subcommand|
            name = annotated_subcommand_name(subcommand.command)
            description = subcommand.summary
            pretty_name = prettify_subcommand(name)
            entry_description(pretty_name, description, name.size)
          end.join("\n")
        end
      end

      # @return [String] The subcommand name with a bullet point which
      #         indicates whether it is the default subcommand.
      #
      # @note   The plus sing emphasizes the that the subcommands are added to
      #         the command. The square brackets conveys a sense of direction
      #         and thus indicates the gravity towards the default command.
      #
      def annotated_subcommand_name(name)
        if name == command.default_subcommand
          "> #{name}"
        else
          "+ #{name}"
        end
      end

      # @return [String] The section describing the options of the command.
      #
      def formatted_options_description
        options = command.options
        options.map do |name, description|
          pretty_name = prettify_option_name(name)
          entry_description(pretty_name, description, name.size)
        end.join("\n")
      end

      # @return [String] The line describing a single entry (subcommand or
      #         option).
      #
      def entry_description(name, description, name_width)
        desc_start = max_name_width + NAME_INDENTATION + DESCRIPTION_SPACES
        result = ''
        result << ' ' * NAME_INDENTATION
        result << name
        result << ' ' * DESCRIPTION_SPACES
        result << ' ' * (max_name_width - name_width)
        result << wrap_with_indent(description, desc_start)
      end

      # @!group Subclasses overrides
      #-----------------------------------------------------------------------#

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
        name.chomp.ansi.green
      end

      # @return [String] A decorated textual representation of the option name.
      #
      #
      def prettify_option_name(name)
        name.chomp.ansi.blue
      end

      # @!group Private helpers
      #-----------------------------------------------------------------------#

      # @return [Array<String>] The list of the subcommands to use in the
      #         banner.
      #
      def subcommands_for_banner
        command.subcommands_for_command_lookup.reject do |subcommand|
          subcommand.summary.nil?
        end.sort_by(&:command)
      end

      # @return [Fixnum] The width of the largest command name or of the
      #         largest option name. Used to align all the descriptions.
      #
      def max_name_width
        unless @max_name_width
          widths = []
          widths << command.options.map { |option| option.first.size }
          widths << subcommands_for_banner.map do |cmd|
            cmd.command.size + SUBCOMMAND_BULLET_SIZE
          end.max
          @max_name_width = widths.flatten.compact.max || 1
        end
        @max_name_width
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
