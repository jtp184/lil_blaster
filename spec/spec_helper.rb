require 'simplecov'
SimpleCov.start

require 'pigpio' if Gem.platforms.last.os == 'linux' && File.read('/proc/cpuinfo') =~ /Raspberry Pi/
require 'bundler/setup'
require 'factory_bot'
require 'lil_blaster'
require 'pry'
require 'fileutils'
require 'tempfile'
require 'tmpdir'
require 'securerandom'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    FactoryBot.find_definitions
  end
end
