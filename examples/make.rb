# encoding: utf-8

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'claide'

# Loading these third-party gems will automatically color some of CLAide’s
# output and strip heredoc strings from its indentation.
require 'colored'
require 'active_support/core_ext/string/strip'

class BeverageMaker < CLAide::Command
  self.abstract_command = true

  self.description = 'Make delicious beverages from the comfort of your terminal.'

  # This would normally default to `beverage-make`, based on the class’ name.
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

  def validate!
    super
    if @sweetner && !%w{ sugar honey }.include?(@sweetner)
      help! "`#{@sweetner}' is not a valid sweetner."
    end
  end

  def run
    puts "* Boiling water…"
    sleep 1
    if @add_milk
      puts "* Adding milk…"
      sleep 1
    end
    if @sweetner
      puts "* Adding #{@sweetner}…"
      sleep 1
    end
  end

  # This command uses an argument for the extra parameter, instead of
  # subcommands for each of the flavor.
  class Tea < BeverageMaker
    self.summary = 'Drink based on cured leaves'

    self.description = <<-DESC
      An aromatic beverage commonly prepared by pouring boiling hot
      water over cured leaves of the Camellia sinensis plant.

      The following flavors are available: black, green, oolong, and white.
    DESC

    self.arguments = '[FLAVOR]'

    def self.options
      [['--iced', 'the ice-tea version']].concat(super)
    end

    def initialize(argv)
      @flavor = argv.shift_argument
      @iced = argv.flag?('iced')
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
      puts "* Infuse #{@flavor} tea…"
      sleep 1
      if @iced
        puts "* Cool off…"
        sleep 1
      end
      puts "* Enjoy!"
    end
  end

  # Unlike the Tea command, this command uses subcommands to specify the flavor.
  #
  # Which one makes more sense is up to you.
  class Coffee < BeverageMaker
    self.abstract_command = true

    self.summary = 'Drink brewed from roasted coffee beans'

    self.description = <<-DESC
      Coffee is a brewed beverage with a distinct aroma and flavor
      prepared from the roasted seeds of the Coffea plant.
    DESC

    def run
      super
      puts "* Grinding #{self.class.command} beans…"
      sleep 1
      puts "* Brewing coffee…"
      sleep 1
      puts "* Enjoy!"
    end

    class BlackEye < Coffee
      self.summary = 'A Black Eye is dripped coffee with a double shot of espresso'
    end

    class Affogato < Coffee
      self.summary = 'A coffee-based beverage (Italian for "drowned")'
    end

    class CaPheSuaDa < Coffee
      self.summary = 'A unique Vietnamese coffee recipe'
    end

    class RedTux < Coffee
      self.summary = 'A Zebra Mocha combined with raspberry flavoring'
    end
  end
end

BeverageMaker.run(ARGV)
