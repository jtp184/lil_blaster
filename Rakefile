require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :docs do
  rd_exclude = RDOC_EXCLUDE.map { |r| "--exclude=#{r}" }.join(' ')

  sh "rdoc --output=docs --format=hanna --all --main=README.md #{rd_exclude}"
end

task :doc_check do
  rd_exclude = RDOC_EXCLUDE.map { |r| "--exclude=#{r}" }.join(' ')

  sh "rdoc -C --output=docs --format=hanna --all --main=README.md #{rd_exclude}"
end

task :reinstall do
  needs_sudo = Gem.platforms.last.os == 'linux'
  sh "#{needs_sudo ? 'sudo ' : ''}gem uninstall lil_blaster"
  sh "#{needs_sudo ? 'sudo ' : ''}rake install"
end
