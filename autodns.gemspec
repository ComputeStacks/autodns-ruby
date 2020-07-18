# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'autodns/version'

Gem::Specification.new do |spec|
  spec.name          = "autodns"
  spec.version       = AutoDNS::VERSION
  spec.authors       = ["Kris Watson"]
  spec.email         = ["kris@computestacks.com"]

  spec.summary       = "AutoDNS Module for ComputeStacks"
  spec.description   = "AutoDNS Module for ComputeStacks"
  spec.homepage      = "https://computestacks.com"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
	end

	spec.metadata['github_repo'] = "ssh://github.com/ComputeStacks/autodns-ruby.git"


  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'httparty', '~> 0.17'

  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rdoc", "~> 6.2"
end
