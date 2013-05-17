desc 'Generate yardoc'
task :doc do
  sh "rm -rf yardoc"
  sh "yardoc"
end

desc 'Run specs'
task :spec do
    sh "bacon #{specs('**')}"
end

task :default => :spec

def specs(dir)
  FileList["spec/#{dir}/*_spec.rb"].shuffle.join(' ')
end
