require_relative 'lib/lil_blaster/version'

Gem::Specification.new do |spec|
  spec.name          = 'lil_blaster'
  spec.version       = LilBlaster::VERSION
  spec.authors       = ['Justin Piotroski']
  spec.email         = ['justin.piotroski@gmail.com']

  spec.summary       = 'Simple interaction with Infrared on Raspberry Pi'
  spec.homepage      = 'https://github.com/jtp184/lil_blaster'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'pry', '~> 0.13.1'
  spec.add_development_dependency 'simplecov', '~> 0.19.0'

  spec.add_runtime_dependency 'pastel', '~> 0.8.0'
  spec.add_runtime_dependency 'strings-case', '~> 0.3.0'
  spec.add_runtime_dependency 'thor', '~> 1.0.1'
  spec.add_runtime_dependency 'tty-config', '~> 0.3.2'
  spec.add_runtime_dependency 'tty-prompt', '~> 0.22.0'
end
