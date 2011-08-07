# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "vostok-sdk/version"

Gem::Specification.new do |s|
  s.name        = "vostok-sdk"
  s.version     = Vostok::SDK::VERSION
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = "http://www.openshift.com"
  s.summary     = %q{Cartridge SDK API for Vostok project}
  s.description = %q{Cartridge SDK API for Vostok project}

  s.rubyforge_project = "vostok-sdk"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency("json_pure", ">=1.4.4", "< 1.5.1")
  s.add_dependency("highline", "~> 1.6.2")
  s.add_dependency("state_machine", "~> 1.0.2")
  s.add_dependency("activemodel", "~> 3.0.9")
  s.add_dependency("parseconfig", "~> 0.5.2")
  s.add_dependency("sqlite3", "~> 1.3.4")
  s.add_dependency("uuid", "~> 2.3.3")
end
