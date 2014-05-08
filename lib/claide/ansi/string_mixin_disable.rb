require 'claide/ansi'

module CLAide
  module ANSI
    # Mixin which adds stubs methods for the `StringMixin`. It is intended to
    # disable ANSI support for a client in a single place.
    #
    module StringMixinDisable
      # Defines stubs for the methods related to foreground and background
      # colors.
      #
      ANSI::COLORS.each_key do |key|
        String.send(:define_method, key) do
          self
        end

        String.send(:define_method, "on_#{key}") do
          self
        end
      end

      # Defines stubs for the methods related to text attributes.
      #
      ANSI::TEXT_ATTRIBUTES.each_key do |key|
        String.send(:define_method, key) do
          self
        end
      end
    end
  end
end

