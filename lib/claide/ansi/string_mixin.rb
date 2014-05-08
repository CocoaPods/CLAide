require 'claide/ansi'

module CLAide
  module ANSI
    # Mixin which adds convenience helpers to the String class to use ANSI
    # escape sequences.
    #
    module StringMixin
      # Defines a method returns a copy of the receiver wrapped in an ANSI
      # sequence for each foreground color (e.g. #blue) and for each background
      # color (e.g. #on_blue).
      #
      # The methods handle nesting of ANSI sequences.
      #
      ANSI::COLORS.each_key do |key|
        String.send(:define_method, key) do
          start_sequence = Graphics::foreground_color(key)
          end_sequence = ANSI::DEFAULT_FOREGROUND_COLOR
          wrap_in_ansi_sequence(start_sequence, end_sequence)
        end

        String.send(:define_method, "on_#{key}") do
          start_sequence = Graphics::background_color(key)
          end_sequence = ANSI::DEFAULT_BACKGROUND_COLOR
          wrap_in_ansi_sequence(start_sequence, end_sequence)
        end
      end

      # Defines a method returns a copy of the receiver wrapped in an ANSI
      # sequence for each text attribute (e.g. #bold).
      #
      # The methods handle nesting of ANSI sequences.
      #
      ANSI::TEXT_ATTRIBUTES.each_key do |key|
        String.send(:define_method, key) do
          start_sequence = Graphics::text_attribute(key)
          code = TEXT_DISABLE_ATTRIBUTES[key]
          end_sequence = Graphics.graphics_mode(code)
          wrap_in_ansi_sequence(start_sequence, end_sequence)
        end
      end

      # Wraps the receiver in the given ANSI sequences, taking care of handling
      # existing sequences for the same family of attributes (i.e. attributes
      # terminated by the same sequence).
      #
      String.send(:define_method, :wrap_in_ansi_sequence) do |open, close|
        replaced = self.gsub(close, open)
        "#{open}#{replaced}#{close}"
      end
    end
  end
end
