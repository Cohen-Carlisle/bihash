Gem::Specification.new do |s|
  s.name        = 'bihash'
  s.version     = '0.0.1'
  s.date        = Date.today.to_s
  s.summary     = 'Bidirectional Hash'
  s.description = 'A simple gem that implements a bidrectional hash'
  s.authors     = ['Cohen Carlisle']
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'http://rubygems.org/gems/bihash'
  s.license     = 'MIT'

  s.add_development_dependency 'bundler', '~> 1.7'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'minitest', '~> 5.5'
end
