# encoding: utf-8

module CLAide
  module Helper
    # @return [Fixnum] The width of the current terminal, unless being piped.
    #
    def self.terminal_width
      unless @terminal_width
        if STDOUT.tty? && system('which tput > /dev/null 2>&1')
          @terminal_width = `tput cols`.to_i
        else
          @terminal_width = 0
        end
      end
      @terminal_width
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
    def self.wrap_with_indent(string, indent)
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
    def self.word_wrap(line, line_width)
      line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip
    end

    # @return [String] Lifted straight from ActiveSupport. Thanks guys!
    #
    def self.strip_heredoc(string)
      if min = string.scan(/^[ \t]*(?=\S)/).min
        string.gsub(/^[ \t]{#{min.size}}/, '')
      else
        string
      end
    end
  end
end
