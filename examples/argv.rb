# encoding: utf-8

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'claide'

argv = CLAide::ARGV.new(['tea', '--no-milk', '--sweetner=honey'])
p argv.arguments          # => ['tea']
p argv.shift_argument     # => 'tea'
p argv.flag?('milk')      # => false
p argv.option('sweetner') # => 'honey'

argv = CLAide::ARGV.new(['tea'])
p argv.flag?('milk', true)         # => true
p argv.option('sweetner', 'sugar') # => 'sugar'
