# encoding: utf-8

if RUBY_VERSION >= '1.9.3'
  require 'codeclimate-test-reporter'

  CodeClimate::TestReporter.configure do |config|
    config.logger.level = Logger::WARN
  end

  CodeClimate::TestReporter.start
end

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

# Specs should produce the same output regardless whether they are called from
# a TTY or not.
#
CLAide::Command.ansi_output = false
require 'claide/ansi/string_mixin_disable'

#-----------------------------------------------------------------------------#

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
