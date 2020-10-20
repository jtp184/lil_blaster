require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

RDOC_EXCLUDE = [].map { |r| "--exclude=#{r}" }.join(' ').freeze

task default: :spec

task :docs do
  sh "rdoc --output=docs --format=hanna --all --main=README.md #{RDOC_EXCLUDE}"
end

task :doc_check do
  sh "rdoc -C --output=docs --format=hanna --all --main=README.md #{RDOC_EXCLUDE}"
end

task :reinstall do
  needs_sudo = Gem.platforms.last.os == 'linux'
  sh "#{needs_sudo ? 'sudo ' : ''}gem uninstall lil_blaster"
  sh "#{needs_sudo ? 'sudo ' : ''}rake install"
end
