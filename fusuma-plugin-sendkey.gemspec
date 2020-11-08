# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fusuma/plugin/sendkey/version'

Gem::Specification.new do |spec|
  spec.name          = 'fusuma-plugin-sendkey'
  spec.version       = Fusuma::Plugin::Sendkey::VERSION
  spec.authors       = ['iberianpig']
  spec.email         = ['yhkyky@gmail.com']

  spec.summary       = 'Fusuma plugin to send keyboard events'
  spec.description   = 'Fusuma::Plugin::Sendkey emulate keyboard events with evdev'
  spec.homepage      = 'https://github.com/iberianpig/fusuma-plugin-sendkey'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'fusuma', '~> 1.7'
  spec.add_dependency 'revdev'
end
