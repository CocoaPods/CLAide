desc 'Generate yardoc'
task :doc do
  sh "rm -rf yardoc"
  sh "yardoc"
end

desc 'Run specs'
task :spec do
  sh "bacon spec/claide_spec.rb"
end

task :default => :spec
