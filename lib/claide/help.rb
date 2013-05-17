module CLAide

  require 'claide/informative_error.rb'

  # The exception class that is raised to indicate a help banner should be
  # shown while running {Command.run}.
  #
  class Help < StandardError
    include InformativeError

    # @return [Command]
    #
    #   The command instance for which a help banner should be shown.
    #
    attr_reader :command

    # @return [String]
    #
    #   The optional error message that will be shown before the help banner.
    #
    attr_reader :error_message

    # @param [Command] command
    #
    #   An instance of a command class for which a help banner should be shown.
    #
    # @param [String] error_message
    #
    #   An optional error message that will be shown before the help banner.
    #   If specified, the exit status, used to terminate the program with, will
    #   be set to `1`, otherwise a {Help} exception is treated as not being a
    #   real error and exits with `0`.
    #
    def initialize(command, error_message = nil)
      @command, @error_message = command, error_message
      @exit_status = @error_message.nil? ? 0 : 1
    end

    # @return [String]
    #
    #   The optional error message, colored in red if {Command.colorize_output}
    #   is set to `true`.
    #
    def formatted_error_message
      if @error_message
        message = "[!] #{@error_message}"
        @command.colorize_output? ? message.red : message
      end
    end

    # @return [String]
    #
    #   The optional error message, combined with the help banner of the
    #   command.
    #
    def message
      [formatted_error_message, @command.formatted_banner].compact.join("\n\n")
    end
  end
end
