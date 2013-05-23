
desc 'Run specs'
task :spec do
  sh "bacon #{specs('**')}"
end

task :default => :spec

#-----------------------------------------------------------------------------#

desc 'Generate yardoc'
task :doc do
  sh "rm -rf yardoc"
  sh "yardoc"
end

#-----------------------------------------------------------------------------#

namespace :bundler do
  require "bundler/gem_tasks"
end

#-----------------------------------------------------------------------------#

desc "Run all specs, build and install gem, commit version change, tag version change, and push everything"
task :release do

  unless ENV['SKIP_CHECKS']
    if `git symbolic-ref HEAD 2>/dev/null`.strip.split('/').last != 'master'
      $stderr.puts "[!] You need to be on the `master' branch in order to be able to do a release."
      exit 1
    end

    if `git tag`.strip.split("\n").include?(gem_version)
      $stderr.puts "[!] A tag for version `#{gem_version}' already exists. Change the version in lib/claide.rb"
      exit 1
    end

    puts "You are about to release `#{gem_version}', is that correct? [y/n]"
    exit if $stdin.gets.strip.downcase != 'y'

    diff_lines = `git diff --name-only`.strip.split("\n")

    diff_lines.delete('Gemfile.lock')
    diff_lines.delete('Changelog.md')
    if diff_lines != ['lib/claide.rb']
      $stderr.puts "[!] Only change the version number in a release commit!"
      $stderr.puts diff_lines
      exit 1
    end
  end

  require 'date'

  # Ensure that the branches are up to date with the remote
  sh "git pull"

  puts "* Running specs"
  silent_sh('rake spec')

  tmp = File.expand_path('../tmp', __FILE__)
  tmp_gems = File.join(tmp, 'gems')

  Rake::Task['bundler:build'].invoke

  puts "* Testing gem installation (tmp/gems)"
  silent_sh "rm -rf '#{tmp}'"
  silent_sh "gem install --install-dir='#{tmp_gems}' #{gem_pkg_path}"

  # Then release
  sh "git commit lib/claide.rb -m 'Release #{gem_version}'"
  sh "git tag -a #{gem_version} -m 'Release #{gem_version}'"
  sh "git push origin master"
  sh "git push origin --tags"

  Rake::Task['bundler:release'].invoke

end

#-----------------------------------------------------------------------------#

def gem_version
  require File.expand_path('../lib/claide', __FILE__)
  CLAide::VERSION
end

def gem_pkg_path
  "pkg/claide-#{gem_version}.gem"
end

def silent_sh(command)
  output = `#{command} 2>&1`
  unless $?.success?
    puts output
    exit 1
  end
  output
end

def specs(dir)
  FileList["spec/#{dir}/*_spec.rb"].shuffle.join(' ')
end

