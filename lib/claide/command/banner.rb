# encoding: utf-8

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
      attr_accessor :ansi_output
      alias_method :ansi_output?, :ansi_output

      def colorize_output
        warn "[!] The use of `CLAide::Command::Banner#colorize_output` has " \
             "been deprecated. Use `CLAide::Command::Banner#ansi_output` " \
             "instead. (Called from: #{caller.first})"
        ansi_output
      end
      alias_method :colorize_output?, :colorize_output

      def colorize_output=(flag)
        warn "[!] The use of `CLAide::Command::Banner#colorize_output=` has " \
             "been deprecated. Use `CLAide::Command::Banner#ansi_output=` " \
             "instead. (Called from: #{caller.first})"
        self.ansi_output = flag
      end

      # @param [Class] command @see command
      # @param [Class] ansi_output @see ansi_output
      #
      def initialize(command, ansi_output = false)
        @command = command
        @ansi_output = ansi_output
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
        max_key_size = opts.map { |opt| opt.first.size }.max

        desc_start = max_key_size + 7 # fixed whitespace in `result` var
        desc_width = terminal_width - desc_start

        opts.map do |key, desc|
          space = ' ' * (max_key_size - key.size)
          result = "    #{prettify_option_name(key)}#{space}   "
          if terminal_width == 0
            result << desc
          else
            space = ' ' * desc_start
            result << word_wrap(desc, desc_width).split("\n").join("\n#{space}")
          end
        end.join("\n")
      end

      # @return [String]
      #
      def prettify_option_name(name)
        ansi_output? ? name.blue : name
      end

      # @return [String]
      #
      def formatted_usage_description
        if message = command.description || command.summary
          message = strip_heredoc(message)
          message = message.split("\n").map { |line| "      #{line}" }.join("\n")
          args = " #{command.arguments}" if command.arguments
          command_signature = prettify_command_in_usage_description(command.full_command, args)
          "    $ #{command_signature}\n\n#{message}"
        end
      end

      # @return [String]
      #
      def prettify_command_in_usage_description(command, args)
        if ansi_output?
          result = "#{command.green}"
          result << "#{args.magenta}" if args
          result
        else
          result = "#{command}"
          result << args if args
          result
        end
        end

      # @return [String]
      #
      def formatted_subcommand_summaries
        subcommands = command.subcommands_for_command_lookup.reject do |subcommand|
          subcommand.summary.nil?
        end.sort_by(&:command)
        unless subcommands.empty?
          command_size = subcommands.map { |cmd| cmd.command.size }.max
          subcommands.map do |subcommand|
            subcommand_string = subcommand.command.ljust(command_size)
            subcommand_string = prettify_subcommand_name(subcommand_string)
            is_default = subcommand.command == command.default_subcommand
            if is_default
              bullet_point = '>'
            else
              bullet_point = '*'
            end
            "    #{bullet_point} #{subcommand_string}   #{subcommand.summary}"
          end.join("\n")
        end
      end

      # @return [String]
      #
      def prettify_subcommand_name(name)
        ansi_output? ? name.green : name
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
