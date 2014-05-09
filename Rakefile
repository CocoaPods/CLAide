require 'bundler/gem_tasks'

task :default => :spec

# Bootstrap
#-----------------------------------------------------------------------------#

desc "Initializes your working copy to run the specs"
task :bootstrap do
  puts "Installing gems"
  `bundle install`
end

#-----------------------------------------------------------------------------#

desc 'Run specs'
task :spec do
  specs = FileList["spec/#{dir}/*_spec.rb"].shuffle.join(' ')
  sh "bundle exec bacon #{specs('**')}"
end
