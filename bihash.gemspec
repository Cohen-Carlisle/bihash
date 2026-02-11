lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bihash/version'

Gem::Specification.new do |s|
  s.name          = 'bihash'
  s.version       = Bihash::VERSION
  s.authors       = ['Cohen Carlisle']
  s.email         = ['cohen.carlisle@gmail.com']

  s.summary       = 'Bidirectional Hash'
  s.description   = 'A simple gem that implements a bidirectional hash'
  s.homepage      = 'https://github.com/Cohen-Carlisle/bihash'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 3.2'

  s.add_development_dependency 'rake', '~> 13.1'
  s.add_development_dependency 'minitest', '~> 5.20'
  s.add_development_dependency 'irb', '~> 1.13'
end
