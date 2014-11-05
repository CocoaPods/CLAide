# -*- encoding: utf-8 -*-
$:.unshift File.expand_path('../lib', __FILE__)
require 'claide'

Gem::Specification.new do |s|
  s.name     = "claide"
  s.version  = CLAide::VERSION
  s.license  = "MIT"
  s.email    = ["eloy.de.enige@gmail.com", "fabiopelosin@gmail.com"]
  s.homepage = "https://github.com/CocoaPods/CLAide"
  s.authors  = ["Eloy Duran", "Fabio Pelosin"]

  s.summary  = "A small command-line interface framework."

  s.files = Dir["lib/**/*.rb"] + %w{ README.markdown LICENSE }
  s.require_paths = %w{ lib }

  ## Make sure you can build the gem on older versions of RubyGems too:
  s.rubygems_version = "1.6.2"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = '>= 2.0.0'
  s.specification_version = 3 if s.respond_to? :specification_version
end
