require 'bundler/gem_tasks'

task :default => :spec

#-- Bootstrap ----------------------------------------------------------------#

desc "Initializes your working copy to run the specs"
task :bootstrap do
  puts "Installing gems"
  `bundle install`
end

#-- Specs --------------------------------------------------------------------#

desc 'Run specs'
task :spec do
  title 'Running Unit Tests'
  files = FileList['spec/**/*_spec.rb'].shuffle.join(' ')
  sh "bundle exec bacon #{files}"

  Rake::Task['rubocop'].invoke
end

#-- Rubocop ------------------------------------------------------------------#

desc 'Checks code style'
task :rubocop do
  title 'Checking code style'
  if RUBY_VERSION >= '1.9.3'
    require 'rubocop'
    cli = Rubocop::CLI.new
    result = cli.run
    abort('RuboCop failed!') unless result == 0
  else
    puts '[!] Ruby > 1.9 is required to run style checks'
  end
end

#-- Helpers ------------------------------------------------------------------#

def title(title)
  cyan_title = "\033[0;36m#{title}\033[0m"
  puts
  puts '-' * 80
  puts cyan_title
  puts '-' * 80
  puts
end
