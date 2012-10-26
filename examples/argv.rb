# encoding: utf-8

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'claide'

argv = CLAide::ARGV.new(['tea', '--no-milk', '--sweetner=honey'])
p argv.shift_argument     # => 'tea'
p argv.shift_argument     # => nil
p argv.flag?('milk')      # => false
p argv.flag?('milk')      # => nil
p argv.option('sweetner') # => 'honey'
p argv.option('sweetner') # => nil

puts

argv = CLAide::ARGV.new(['tea', 'coffee'])
p argv.arguments  # => ['tea', 'coffee']
p argv.arguments! # => ['tea', 'coffee']
p argv.arguments  # => []

puts

argv = CLAide::ARGV.new(['tea'])
p argv.flag?('milk', true)         # => true
p argv.option('sweetner', 'sugar') # => 'sugar'
