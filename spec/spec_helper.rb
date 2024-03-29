# encoding: utf-8

require 'simplecov'
SimpleCov.start

#-----------------------------------------------------------------------------#

require 'pathname'
ROOT = Pathname.new(File.expand_path('../../', __FILE__))
$LOAD_PATH.unshift((ROOT + 'lib').to_s)
$LOAD_PATH.unshift((ROOT + 'spec').to_s)

require 'bundler/setup'
require 'bacon'
require 'mocha-on-bacon'
require 'pretty_bacon'
require 'claide'
require 'spec_helper/fixtures'
require 'spec_helper/rubygems'
require 'spec_helper/string_ext'

#-- Helpers ------------------------------------------------------------------#

module Bacon
  class Context
    def should_raise_help(error_message)
      error = nil
      begin
        yield
      rescue CLAide::Help => e
        error = e
      end
      error.should.not.nil?
      error.error_message.should == error_message
    end
  end
end

#-- Spec environment ---------------------------------------------------------#

# Specs should produce the same output regardless whether they are called from
# a TTY or not.
#
CLAide::Command.ansi_output = false

Mocha::Configuration.prevent(:stubbing_non_existent_method)

module Bacon
  class Context
    old_run_requirement = instance_method(:run_requirement)
    define_method(:run_requirement) do |description, spec|
      ::CLAide::ANSI.disabled = true
      old_run_requirement.bind(self).call(description, spec)
    end
  end
end
