require 'test_helper'

module Openshift::SDK::Model
  class CartridgeTest < Test::Unit::TestCase
    include ActiveModel::Lint::Tests

    def model
      Cartridge.new
    end

    def setup
      Mocha::Mockery.instance.stubba.unstub_all 
      @cart = Cartridge.new("mock-1.0","/opt/openshift/cartridges/mock-1.0",["mock"], ["php"], ["libxml"], true, 
      ["/opt/openshift/cartridges/mock-1.0/openshift/hooks/hook1", "/opt/openshift/cartridges/mock-1.0/openshift/hooks/hook2"])
    end
    
    def test_is_installed
      assert_equal true, @cart.installed?
    end
    
    def test_list_installed
      Cartridge.expects(:what_provides).returns([
          Cartridge.new("mock-1.0","/opt/openshift/cartridges/mock-1.0",["mock"], ["php"], ["libxml"], true, []),
          Cartridge.new("php-1.0","/opt/openshift/cartridges/php-1.0",["php"], [], [], false, []),
        ])
      carts = Cartridge.list_installed
      assert_equal 1, carts.size
      assert_equal "mock-1.0", carts[0].name
    end
    
    def test_list_available
      Cartridge.expects(:what_provides).returns([
          Cartridge.new("mock-1.0","/opt/openshift/cartridges/mock-1.0",["mock"], ["php"], ["libxml"], true, []),
          Cartridge.new("php-1.0","/opt/openshift/cartridges/php-1.0",["php"], [], [], false, []),
        ])
      carts = Cartridge.list_available
      assert_equal 2, carts.size
      assert_equal "php-1.0", carts[1].name
    end
    
    def test_what_provides
      RPM.expects(:what_provides).with("openshift-feature-php").returns(YAML.load("---\n- !ruby/object:Openshift::SDK::Model::RPM\n  dependencies:\n  - openshift-feature-www-dynamic\n  provides:\n  - openshift-cartridge-php = 1.0.0-1\n  - openshift-feature-php\n  - openshift-feature-php(version) = 5.3.2\n  hooks:\n  - /opt/openshift/cartridges/openshift-cartridge-php-1.0.0/openshift/hooks/configure\n  - /opt/openshift/cartridges/openshift-cartridge-php-1.0.0/openshift/hooks/deconfigure\n  - /opt/openshift/cartridges/openshift-cartridge-php-1.0.0/openshift/hooks/start\n  - /opt/openshift/cartridges/openshift-cartridge-php-1.0.0/openshift/hooks/stop\n  is_installed: true\n  name: openshift-cartridge-php-1.0.0-1.noarch\n  version: 1.0.0\n  summary: php\n  manifest: /opt/openshift/cartridges/openshift-cartridge-php-1.0.0/openshift/manifest.yml\n"))
      Cartridge.expects(:from_rpm).once.returns(Cartridge.new("php-1.0","/opt/openshift/cartridges/php-1.0",["php"], [], [], false, []))
      carts = Cartridge.what_provides("php")
      assert_equal 1,carts.size
      php = carts[0]
      assert_equal "php-1.0", php.name
    end
    
    def test_from_rpm_installed
      Cartridge.expects(:from_opm).once.returns(Cartridge.new("php-1.0","/opt/openshift/cartridges/php-1.0",["php", "php(version) = 5.3.2"], ["www-dynamic"], [], false, []))
      cart = Cartridge.from_rpm(YAML.load("---\n- !ruby/object:Openshift::SDK::Model::RPM\n  dependencies:\n  - openshift-feature-www-dynamic\n  provides:\n  - openshift-cartridge-php = 1.0.0-1\n  - openshift-feature-php\n  - openshift-feature-php(version) = 5.3.2\n  hooks:\n  - /opt/openshift/cartridges/openshift-cartridge-php-1.0.0/openshift/hooks/configure\n  - /opt/openshift/cartridges/openshift-cartridge-php-1.0.0/openshift/hooks/deconfigure\n  - /opt/openshift/cartridges/openshift-cartridge-php-1.0.0/openshift/hooks/start\n  - /opt/openshift/cartridges/openshift-cartridge-php-1.0.0/openshift/hooks/stop\n  is_installed: true\n  name: openshift-cartridge-php-1.0.0-1.noarch\n  version: 1.0.0\n  summary: php\n  manifest: /opt/openshift/cartridges/openshift-cartridge-php-1.0.0/openshift/manifest.yml\n")[0])
      assert_equal true,cart.hooks.include?("/opt/openshift/cartridges/openshift-cartridge-php-1.0.0/openshift/hooks/stop")
      assert_equal "php-1.0", cart.name
      assert_equal "0.0", cart.version
      assert_equal "noarch", cart.architecture
      assert_equal ["php", "php(version) = 5.3.2"], cart.provides_feature
      assert_equal ["www-dynamic"], cart.requires_feature
      assert_equal [], cart.conflicts_feature
      assert_equal [], cart.requires
      assert_equal false, cart.is_installed
    end
    
    def test_from_rpm
      cart = Cartridge.from_rpm(YAML.load("---\n- !ruby/object:Openshift::SDK::Model::RPM\n  dependencies:\n  - openshift-feature-www-dynamic\n  provides:\n  - openshift-cartridge-php = 1.0.0-1\n  - openshift-feature-php\n  - openshift-feature-php(version) = 5.3.2\n  hooks: []\n  is_installed: false\n  name: openshift-cartridge-php-1.0.0-1.noarch\n  version: 1.0.0\n  summary: php\n")[0])
      assert_equal "php", cart.name
      assert_equal "1.0.0", cart.version
      assert_equal "noarch", cart.architecture
      assert_equal ["php", "php(version) = 5.3.2"], cart.provides_feature
      assert_equal ["www-dynamic"], cart.requires_feature
      assert_equal [], cart.conflicts_feature
      assert_equal [], cart.requires
      assert_equal false, cart.is_installed
      assert_equal "php", cart.summary
    end
    
    def test_from_manifest_yaml
      #Test to see that manifest supports required keys
      manifest = <<EOF
Name: php
Display-Name: php v1.0.0 (noarch)
Description: Cartridge packaging PHP versions 5.3.2 upto 5.4.0
Version: 1.0.0
License: GPLv2
Vendor: PHP
Provides: 
  - "php"
Requires: 
  - "www-dynamic"
Conflicts:
Native-Requires: 
  - "php >= 5.3.2"
Architecture: noarch
Descriptor:
EOF
      Cartridge.new.from_manifest_yaml(manifest)
    end
    
    def test_from_manifest_yaml_2
      #Test to see that manifest errors on unrecognized keys
      manifest = <<EOF
Name: php
Display-Name: php v1.0.0 (noarch)
Description: Cartridge packaging PHP versions 5.3.2 upto 5.4.0
Version: 1.0.0
License: GPLv2
Vendor: PHP
Provides: 
  - "php"
Requires: 
  - "www-dynamic"
Conflicts:
Native-Requires: 
  - "php >= 5.3.2"
Architecture: noarch
Foobar:
Descriptor:
EOF
      assert_raise(RuntimeError){Cartridge.new.from_manifest_yaml(manifest)}
    end
  end
  
  def teardown
    Mocha::Mockery.instance.stubba.unstub_all
  end
end
