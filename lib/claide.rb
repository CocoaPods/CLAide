# encoding: utf-8

# The mods of interest are {CLAide::ARGV}, {CLAide::Command}, and
# {CLAide::InformativeError}
#
module CLAide
  # @return [String]
  #
  #   CLAide’s version, following [semver](http://semver.org).
  #
  VERSION = '0.9.1'

  require 'claide/ansi'
  require 'claide/argument'
  require 'claide/argv'
  require 'claide/command'
  require 'claide/help'
  require 'claide/informative_error'
end
