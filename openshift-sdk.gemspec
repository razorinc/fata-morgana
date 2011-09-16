# OS independent path locations
BIN_DIR  = File.join("bin", "*")
CONF_DIR = File.join("conf", "*")
LIB_DIR  = File.join(File.join("lib", "**"), "*.rb")
TEST_DIR  = File.join(File.join("test", "**"), "*")

Gem::Specification.new do |s|
  s.name        = "openshift-sdk"
  s.version     = /(Version: )(.*)/.match(File.read("openshift-sdk.spec"))[2]
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = "http://www.openshift.com"
  s.summary     = %q{Cartridge SDK API for Openshift project}
  s.description = %q{Cartridge SDK API for Openshift project}

  s.rubyforge_project = "openshift-sdk"
  s.files       = Dir[LIB_DIR] + Dir[BIN_DIR] + Dir[CONF_DIR] + Dir[TEST_DIR]
  s.files       += %w(ARCHITECTURE README.md Rakefile Gemfile openshift-sdk.spec)
  s.executables = Dir[BIN_DIR].map {|binary| File.basename(binary)}
  s.require_paths = ["lib"]
  s.add_dependency("json_pure", "1.4.6")
  s.add_dependency("highline", "1.5.1")
  s.add_dependency("state_machine", "1.0.1")
  s.add_dependency("parseconfig", "0.5.2")
  s.add_dependency("sqlite3", "1.3.3")
  if RUBY_VERSION == "1.8.7"
    s.add_dependency("activemodel", "3.0.5")
    s.add_development_dependency('rcov', "0.9.10")
  end
  s.add_development_dependency('mocha', "0.9.8")
  s.add_development_dependency('rake', "0.9.2")
end
