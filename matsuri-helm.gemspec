
# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'matsuri/traefik/version'

Gem::Specification.new do |spec|
  spec.name          = "matsuri-traefik"
  spec.version       = Matsuri::Traefik::VERSION
  spec.authors       = ["Ho-Sheng Hsiao"]
  spec.email         = ["talktohosh@gmail.com"]

  spec.summary       = %q{Helm support Matsuri}
  spec.description   = %q{Managing Helm releases via Matsuri}
  spec.homepage      = "https://github.com/matsuri-rb/matsuri-traefik"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'matsuri'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
