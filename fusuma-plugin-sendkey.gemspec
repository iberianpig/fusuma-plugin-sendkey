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
  spec.files          = Dir['{bin,lib,exe}/**/*', 'LICENSE*', 'README*', '*.gemspec']
  spec.test_files     = Dir['{test,spec,features}/**/*']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5.1' # https://packages.ubuntu.com/search?keywords=ruby&searchon=names&exact=1&suite=all&section=main
  # support bionic (18.04LTS) 2.5.1

  spec.add_dependency 'fusuma', '~> 2.0'
  spec.add_dependency 'revdev'
end
