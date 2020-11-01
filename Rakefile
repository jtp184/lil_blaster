require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

# By default don't assume we have the HAT, just run the tests we need to
RSpec::Core::RakeTask.new(:test) do |t|
  t.rspec_opts = '--tag ~@hardware'
end

RDOC_EXCLUDE = %w[
  bin/setup
  bin/console
  coverage
  pkg
  Gemfile
  Gemfile.lock
  Rakefile
  tmp
  docs
  spec
].map { |r| "--exclude=#{r}" }.join(' ').freeze

task default: :test

task :docs do
  sh "rdoc --output=docs --format=hanna --all --main=README.md #{RDOC_EXCLUDE}"
end

task :docs? do
  sh "rdoc -C --output=docs --format=hanna --all --main=README.md #{RDOC_EXCLUDE}"
end

task :reinstall do
  needs_sudo = Gem.platforms.last.os == 'linux'
  sh "#{needs_sudo ? 'sudo ' : ''}gem uninstall lil_blaster"
  sh "#{needs_sudo ? 'sudo ' : ''}rake install"
end
