# encoding: utf-8

#-- Bootstrap --------------------------------------------------------------#

desc 'Initializes your working copy to run the specs'
task :bootstrap do
  title 'Installing gems'
  sh 'gem install bundler'
  sh 'bundle install'
end

begin
  require 'bundler/gem_tasks'
  task :default => :spec

  #-- Specs ------------------------------------------------------------------#

  desc 'Run specs'
  task :spec do
    title 'Running Unit Tests'
    files = FileList['spec/**/*_spec.rb'].shuffle.join(' ')
    sh "bundle exec bacon #{files}"

    Rake::Task['rubocop'].invoke if RUBY_VERSION >= '1.9.3'
  end

  #-- Rubocop ----------------------------------------------------------------#

  if RUBY_VERSION >= '1.9.3'
    require 'rubocop/rake_task'
    Rubocop::RakeTask.new
  end

rescue LoadError
  $stderr.puts '[!] Some Rake tasks haven been disabled because the ' \
    'environment couldn’t be loaded. Be sure to run `rake bootstrap` first.'
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
