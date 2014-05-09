# encoding: utf-8

# The mods of interest are {CLAide::ARGV}, {CLAide::Command}, and
# {CLAide::InformativeError}
#
module CLAide
  # @return [String]
  #
  #   CLAide’s version, following [semver](http://semver.org).
  #
  VERSION = '0.5.0'

  require 'claide/ansi'
  require 'claide/argv'
  require 'claide/command'
  require 'claide/help'
  require 'claide/informative_error'
  require 'claide/mixins'
end
