# encoding: utf-8

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
end

#-----------------------------------------------------------------------------#

require 'pathname'
ROOT = Pathname.new(File.expand_path('../../', __FILE__))
$LOAD_PATH.unshift((ROOT + 'lib').to_s)
$LOAD_PATH.unshift((ROOT + 'spec').to_s)

require 'bundler/setup'
require 'rspec'
require 'mocha/api'
require 'claide'
require 'spec_helper/fixtures'
require 'spec_helper/rubygems'
require 'spec_helper/string_ext'

#-- Helpers ------------------------------------------------------------------#

module SpecHelper
  module Help
    def should_raise_help(error_message, &block)
      expect(&block).to raise_error(CLAide::Help) do |error|
        expect(error.error_message).to eq(error_message)
      end
    end
  end
end

#-- Spec environment ---------------------------------------------------------#

# Specs should produce the same output regardless whether they are called from
# a TTY or not.
#
CLAide::Command.ansi_output = false

Mocha.configure { |c| c.stubbing_non_existent_method = :prevent }

RSpec.configure do |config|
  config.mock_with :mocha
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.include SpecHelper::Help

  config.before do
    ::CLAide::ANSI.disabled = true
  end
end
