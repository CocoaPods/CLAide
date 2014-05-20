# encoding: utf-8

module CLAide
  # This class is used to represent individual arguments to present to
  # the command help banner
  #
  class Argument
    # @return [Array<String>]
    #         List of alternate names for the parameters
    attr_reader :names

    # @return [Boolean]
    #         Indicates if the argument is required (not optional)
    #
    attr_accessor :required
    alias_method :required?, :required

    # @return [Boolean]
    #         Indicates if the argument is optional (not required)
    #
    # @note This is a commodity accessor for !required?
    #
    def optional?
      !@required
    end

    # @param [String,Array<String>] names
    #        List of the names of each parameter alternatives
    #        For commodity, if there is only one alternative for that parameter
    #        then we can directly use the String instead of a 1-item Array
    #
    # @param [Boolean] required
    #        true if the parameter is required, false if it is optional
    #
    # @example
    #
    #   # A required parameter that can be either a NAME or URL
    #   Argument.new(%(NAME URL), true)
    #
    def initialize(names, required)
      @names = Array(names)
      @required = required
    end

    # Commodity constructor
    #
    # @example
    #
    #   # A required parameter called 'NAME'
    #   Argument['NAME', true]
    #
    # @see Argument#initialize
    #
    def self.[](*params)
      new(*params)
    end

    # @return [Boolean] true on equality
    #
    # @param [Argument] other the Argument compared against
    #
    def ==(other)
      names == other.names && required == other.required
    end
  end
end
