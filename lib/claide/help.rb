# encoding: utf-8

module CLAide
  require 'claide/informative_error'

  # The exception class that is raised to indicate a help banner should be
  # shown while running {Command.run}.
  #
  class Help < StandardError
    include InformativeError

    # @return [String] The banner containing the usage instructions of the
    # command to show in the help.
    #
    attr_reader :banner

    # @return [String] An optional error message that will be shown before the
    #         help banner.
    #
    attr_reader :error_message

    # @return [Bool] Whether the error message should use ANSI codes to
    #         prettify output.
    #
    attr_reader  :ansi_output
    alias_method :ansi_output?, :ansi_output

    def colorize
      warn "[!] The use of `CLAide::Help#colorize` has been " \
           "deprecated. Use `CLAide::Help#ansi_output` instead. " \
           "(Called from: #{caller.first})"
      ansi_output
    end
    alias_method :colorize?, :colorize

    # @param [String] banner @see banner
    # @param [String] error_message @see error_message
    #
    # @note  If an error message is provided, the exit status, used to
    #        terminate the program with, will be set to `1`, otherwise a {Help}
    #        exception is treated as not being a real error and exits with `0`.
    #
    def initialize(banner, error_message = nil, ansi_output = false)
      @banner = banner
      @error_message = error_message
      @ansi_output = ansi_output
      @exit_status = @error_message.nil? ? 0 : 1
    end

    # @return [String] The optional error message, colored in red if
    #         {Command.colorize_output} is set to `true`.
    #
    def formatted_error_message
      if error_message
        message = "[!] #{error_message}"
        prettify_error_message(message)
      end
    end

    # @return [String]
    #
    def prettify_error_message(message)
      ansi_output? ? message.red : message
    end

    # @return [String] The optional error message, combined with the help
    #         banner of the command.
    #
    def message
      [formatted_error_message, banner].compact.join("\n\n")
    end
  end
end
