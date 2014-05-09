# encoding: utf-8

require 'claide/ansi/cursor'
require 'claide/ansi/graphics'

module CLAide
  # Provides support for ANSI Escape sequences
  #
  # For more information see:
  #
  # - http://ascii-table.com/ansi-escape-sequences.php
  # - http://en.wikipedia.org/wiki/ANSI_escape_code
  #
  # This functionality has been inspired and derived from the following gems:
  #
  # - colored
  # - colorize
  #
  class ANSI
    extend Cursor
    extend Graphics

    class << self
      attr_accessor :disabled
    end

    # @return [Hash]
    #
    TEXT_ATTRIBUTES = {
      :bold       => 1,
      :underline  => 4,
      :blink      => 5,
      :reverse    => 7,
      :hidden     => 8,
    }

    # Return [String]
    #
    RESET_SEQUENCE = "\e[0m"

    # @return [Hash]
    #
    TEXT_DISABLE_ATTRIBUTES = {
      :bold       => 21,
      :underline  => 24,
      :blink      => 25,
      :reverse    => 27,
      :hidden     => 28,
    }

    # @return [Hash]
    #
    COLORS = {
      :black      => 0,
      :red        => 1,
      :green      => 2,
      :yellow     => 3,
      :blue       => 4,
      :magenta    => 5,
      :cyan       => 6,
      :white      => 7,
    }

    # Return [String]
    #
    DEFAULT_FOREGROUND_COLOR = "\e[39m"

    # Return [String]
    #
    DEFAULT_BACKGROUND_COLOR = "\e[49m"

    # Return [Fixnum]
    #
    def self.code_for_key(key, map)
      unless key
        raise ArgumentError, 'A key must be provided'
      end
      code = map[key]
      unless code
        raise ArgumentError, "Unsupported key: `#{key}`"
      end
      code
    end
  end
end

#-- String mixin -------------------------------------------------------------#

require 'claide/ansi/string_escaper'

class String
  # @return [StringEscaper] An object which provides convenience methods to
  #         wrap the receiver in ANSI sequences.
  #
  # @example
  #   "example".ansi.yellow #=> "\e[33mexample\e[39m"
  #   "example".ansi.on_red #=> "\e[41mexample\e[49m"
  #   "example".ansi.bold   #=> "\e[1mexample\e[21m"
  #
  def ansi
    CLAide::ANSI::StringEscaper.new(self)
  end
end
