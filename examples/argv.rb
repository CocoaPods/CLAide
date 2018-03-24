# encoding: utf-8

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require 'claide'

argv = CLAide::ARGV.new(['tea', '--no-milk', '--sweetener=honey'])
p argv.shift_argument     # => 'tea'
p argv.shift_argument     # => nil
p argv.flag?('milk')      # => false
p argv.flag?('milk')      # => nil
p argv.option('sweetener') # => 'honey'
p argv.option('sweetener') # => nil

puts

argv = CLAide::ARGV.new(%w(tea coffee))
p argv.arguments  # => ['tea', 'coffee']
p argv.arguments! # => ['tea', 'coffee']
p argv.arguments  # => []

puts

argv = CLAide::ARGV.new(['tea'])
p argv.flag?('milk', true)         # => true
p argv.option('sweetener', 'sugar') # => 'sugar'
