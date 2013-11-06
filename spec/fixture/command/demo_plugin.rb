# encoding: utf-8
module Fixture
  class Command
    class DemoPlugin < Command
      self.summary = 'Plugins!'
      self.description = <<-DESC
        Let’s add plugins to CLAide and CocoaPods.
      DESC
      self.arguments = '[NAME]'

      attr_reader :name
      def initialize(argv)
        @name = argv.shift_argument
        super
      end
    end
  end
end
