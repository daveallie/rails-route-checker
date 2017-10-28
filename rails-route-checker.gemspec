
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails-route-checker/version'

Gem::Specification.new do |spec|
  spec.name          = 'rails-route-checker'
  spec.version       = RailsRouteChecker::VERSION
  spec.authors       = ['Dave Allie']
  spec.email         = ['dave@daveallie.com']

  spec.summary       = 'Blah'
  spec.description   = 'Blah'
  spec.homepage      = 'https://github.com/daveallie/rails-route-checker'
  spec.license       = 'MIT'

  spec.files         = Dir['exe/*'] + Dir['lib/**/*'] +
                       ['Gemfile', 'rails-route-checker.gemspec']

  #   `git ls-files -z`.split("\x0").reject do |f|
  #   f.match(%r{^(test|spec|features)/})
  # end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop', '~> 0.51'
end
