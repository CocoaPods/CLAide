# encoding: utf-8

module CLAide
  class ANSI
    # Provides support for generating escape sequences relative to the position
    # of the cursor and to erase parts of text.
    #
    module Cursor
      # @return [String] The escape sequence to set the cursor at the
      #         given line.
      #
      # @param  [Fixnum] line
      #         The line where to place the cursor.
      #
      # @param  [Fixnum] column
      #         The column where to place the cursor.
      #
      def self.set_cursor_position(line = 0, column = 0)
        "\e[#{line};#{column}H"
      end

      # @return [String] The escape sequence to set the cursor at the
      #         given line.
      #
      # @param  [Fixnum] lines
      #         The amount of lines the cursor should be moved to.
      #         Negative values indicate up direction and positive ones
      #         down direction.
      #
      # @param  [Fixnum] columns
      #         The amount of columns the cursor should be moved to.
      #         Negative values indicate left direction and positive ones
      #         right direction.
      #
      def self.move_cursor(lines, columns)
        result = "\e["
        if lines.nonzero?
          wants_coma = true
          if lines < 0
            result << "#{-lines}A"
          else
            result << "#{lines}B"
          end
        end

        if columns.nonzero?
          if wants_coma
            result << ';'
          end
          if columns > 0
            result << "#{columns}C"
          else
            result << "#{-columns}D"
          end
        end
        result
      end

      # @return [String] The escape sequence to save the cursor position.
      #
      def self.save_cursor_position
        "\e[s"
      end

      # @return [String] The escape sequence to restore the cursor to the
      #         previously saved position. This sequence also clears all the
      #         output after the position.
      #
      def self.restore_cursor_position
        "\e[u"
      end

      # @return [String] The escape sequence to erase the display.
      #
      def self.erase_display
        "\e[2J"
      end

      # @return [String] The escape sequence to erase a line form the
      #         cursor position to then end.
      #
      def self.erase_line
        "\e[K"
      end
    end
  end
end
