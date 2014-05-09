require 'claide/ansi'

class String
  # @return [StringDisabledEscaper] An object which provides convenience
  #         methods to disable the methods of the StringEscaper. It is intended
  #         to allow clients to disable ANSI output from a central location.
  #
  # @example
  #   "example".ansi.yellow #=> "example"
  #   "example".ansi.on_red #=> "example"
  #   "example".ansi.bold   #=> "example"
  #
  def ansi
    CLAide::ANSI::StringDisabledEscaper.new(self)
  end
end

#-----------------------------------------------------------------------------#

module CLAide
  module ANSI
    # Provides support to wrap strings in ANSI sequences.
    #
    class StringDisabledEscaper
      # @param  [String] The string to wrap.
      #
      def initialize(string)
        @string = string
      end

      ANSI::COLORS.each_key do |key|
        # @return [String] Defines stubs for the methods related to
        # foreground colors.
        #
        define_method key do
          @string
        end

        # @return [String] Defines stubs for the methods related to
        # background colors.
        #
        define_method "on_#{key}" do
          @string
        end
      end

      ANSI::TEXT_ATTRIBUTES.each_key do |key|
        # @return [String] Defines stubs for the methods related to
        # text attributes.
        #
        define_method key do
          @string
        end
      end
    end
  end
end
