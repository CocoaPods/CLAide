# encoding: utf-8

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'claide'

# Loading these third-party gems will automatically color some of CLAide’s
# output, not require us to provide a string version of the command, and strip
# heredoc strings from its indentation.
require 'colored'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/string/strip'

class BeverageMaker < CLAide::Command
  self.abstract_command = true

  self.description = 'Make delicious beverages from the comfort of your terminal.'

  # This is actually only needed if you have not loaded ActiveSupport’s
  # ‘inflector’ module, or you don’t want the name to be based on the command
  # class.
  self.command = 'make'

  def self.options
    [
      ['--no-milk', 'Don’t add milk to the beverage'],
      ['--sweetner=[sugar|honey]', 'Use one of the available sweetners']
    ].concat(super)
  end

  def initialize(argv)
    @add_milk = argv.flag?('milk', true)
    @sweetner = argv.option('sweetner')
    super
  end

  def run
    puts "1. Boiling water…"
    sleep 1
  end

  class Tea < BeverageMaker
    self.summary = 'Drink based on cured leaves'

    # CLaide will strip the preceding indentation from the description, because
    # we have loaded ActiveSupport’s ‘strip’ module.
    self.description = <<-DESC
      An aromatic beverage commonly prepared by pouring boiling hot
      water over cured leaves of the Camellia sinensis plant.

      The following flavors are available: black, green, oolong, and white.
    DESC

    self.arguments = '[FLAVOR]'

    def initialize(argv)
      @flavor = argv.shift_argument
      super
    end

    def validate!
      super
      if @flavor.nil?
        help! "A flavor argument is required."
      end
      unless %w{ black green oolong white }.include?(@flavor)
        help! "`#{@flavor}' is not a valid flavor."
      end
    end

    def run
      super
      puts "2. Infuse #{@flavor} tea…"
      sleep 1
      puts "3. Enjoy!"
    end
  end

  class Coffee < BeverageMaker
    self.summary = 'Drink brewed from roasted coffee beans'

    # CLaide will strip the preceding indentation from the description, because
    # we have loaded ActiveSupport’s ‘strip’ module.
    self.description = <<-DESC
      Coffee is a brewed beverage with a distinct aroma and flavor
      prepared from the roasted seeds of the Coffea plant.
    DESC
  end
end

BeverageMaker.run(ARGV)
