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

    def self.format_markdown(string, indent = 0)
      paragraphs = Helper.strip_heredoc(string).split("\n\n")
      paragraphs = paragraphs.map do |paragraph|
        if paragraph.start_with?(' ' * 4)
          result = paragraph
        else
          full_line = paragraph.gsub("\n", ' ')
          result = wrap_with_indent(full_line, indent)
        end
        result.insert(0, ' ' * indent).rstrip
      end
      paragraphs.join("\n\n")
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
    def self.wrap_with_indent(string, indent = 0)
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
    # rubocop:disable all
    def self.levenshtein_distance(a, b)
      a, b = a.downcase, b.downcase
      costs = Array(0..b.length)
      (1..a.length).each do |i|
        costs[0], nw = i, i - 1
        (1..b.length).each do |j|
          costs[j], nw = [
            costs[j] + 1, costs[j - 1] + 1, a[i - 1] == b[j - 1] ? nw : nw + 1
          ].min, costs[j]
        end
      end
      costs[b.length]
    end
    # rubocop:enable all
  end
end
