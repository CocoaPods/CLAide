# encoding: utf-8
module Fixture
  class CommandPluginable
    class DemoPlugin < CommandPluginable
      self.summary = 'Plugins!'
      self.description = <<-DESC
        Let’s add plugins to CLAide and CocoaPods.
      DESC
      self.arguments = [
        CLAide::Argument.new('NAME', false),
      ]

      attr_reader :name
      def initialize(argv)
        @name = argv.shift_argument
        super
      end
    end
  end
end
