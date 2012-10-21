# -*- encoding: utf-8 -*-
$:.unshift File.expand_path('../lib', __FILE__)
require 'cli_aide'

Gem::Specification.new do |s|
  s.name     = "cli_aide"
  s.version  = CLIAide::VERSION
  s.date     = Date.today
  s.license  = "MIT"
  s.email    = ["eloy.de.enige@gmail.com", "fabiopelosin@gmail.com"]
  s.homepage = "https://github.com/CocoaPods/CLIAide"
  s.authors  = ["Eloy Duran", "Fabio Pelosin"]

  s.summary     = "A small CLI framework."

  s.files = %w{ lib/cli_aide.rb README.markdown LICENSE }
  s.require_paths = %w{ lib }

  ## Make sure you can build the gem on older versions of RubyGems too:
  s.rubygems_version = "1.6.2"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.specification_version = 3 if s.respond_to? :specification_version
end
