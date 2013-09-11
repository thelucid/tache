# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tache/version'

Gem::Specification.new do |gem|
  gem.name          = "tache"
  gem.version       = Tache::VERSION
  gem.authors       = ["Jamie Hill"]
  gem.email         = ["jamie@thelucid.com"]
  gem.description   = %q{Just enough Mustache for end users}
  gem.summary       = %q{Tache is a full Mustache implementation** with the addition of 'safe views'.}
  gem.homepage      = "https://github.com/thelucid/tache"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-test'
  gem.add_development_dependency 'rb-inotify'
  gem.add_development_dependency 'rb-fsevent'
  gem.add_development_dependency 'rb-fchange'
end
