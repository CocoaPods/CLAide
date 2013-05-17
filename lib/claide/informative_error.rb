module CLAide

  # Including this module into an exception class will ensure that when raised,
  # while running {Command.run}, only the message of the exception will be
  # shown to the user. Unless disabled with the `--verbose` flag.
  #
  # In addition, the message will be colored red, if {Command.colorize_output}
  # is set to `true`.
  #
  module InformativeError
    attr_writer :exit_status

    # @return [Numeric]
    #
    #   The exist status code that should be used to terminate the program with.
    #
    #   Defaults to `1`.
    #
    def exit_status
      @exit_status ||= 1
    end
  end
end
