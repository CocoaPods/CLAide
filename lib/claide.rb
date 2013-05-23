# encoding: utf-8

# The mods of interest are {CLAide::ARGV}, {CLAide::Command}, and
# {CLAide::InformativeError}
#
module CLAide

  # @return [String]
  #
  #   CLAide’s version, following [semver](http://semver.org).
  #
  VERSION = '0.3.2'

  require 'claide/argv.rb'
  require 'claide/command.rb'
  require 'claide/help.rb'
  require 'claide/informative_error.rb'

end
