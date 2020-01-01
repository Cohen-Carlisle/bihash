# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bihash/version'

Gem::Specification.new do |s|
  s.name          = 'bihash'
  s.version       = Bihash::VERSION
  s.authors       = ['Cohen Carlisle']
  s.email         = ['cohen.carlisle@gmail.com']

  s.summary       = 'Bidirectional Hash'
  s.description   = 'A simple gem that implements a bidrectional hash'
  s.homepage      = 'http://rubygems.org/gems/bihash'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ['lib']

  s.add_development_dependency 'bundler', '~> 2.1'
  s.add_development_dependency 'rake', '>= 13'
  s.add_development_dependency 'minitest', '~> 5.13'
  s.add_development_dependency 'pry', '~> 0.12'
end
