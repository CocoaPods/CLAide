desc 'Generate yardoc'
task :doc do
  sh "yardoc -m markdown lib"
end

desc 'Run specs'
task :spec do
  sh "bacon spec/claide_spec.rb"
end

task :default => :spec
