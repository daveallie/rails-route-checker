# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails-route-checker/version'

Gem::Specification.new do |spec|
  spec.name          = 'rails-route-checker'
  spec.version       = RailsRouteChecker::VERSION
  spec.authors       = ['Dave Allie']
  spec.email         = ['dave@daveallie.com']

  spec.summary       = 'A linting tool for your Rails routes'
  spec.description   = 'A linting tool that helps you find any routes defined in your routes.rb file that ' \
                       "don't have a corresponding controller action, and find any _path or _url calls that don't " \
                       'have a corresponding route in the routes.rb file.'
  spec.homepage      = 'https://github.com/daveallie/rails-route-checker'
  spec.license       = 'MIT'

  spec.files         = Dir['exe/*'] + Dir['lib/**/*'] +
                       %w[Gemfile rails-route-checker.gemspec]
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rails'

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 0.86'
  spec.add_development_dependency 'appraisal', '~> 2.5.0'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'propshaft'
end
