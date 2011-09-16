require 'test_helper'
require 'parseconfig'

module Openshift::SDK
  class ConfigTest < Test::Unit::TestCase
    def test_instance
      assert_not_nil Config.instance
    end

    def test_fail_on_new
      assert_raise(NoMethodError) { Config.new }
    end

    def test_linux_config_exists
      linux_conf = '/etc/openshift/openshift.conf'
      File.expects(:exists?).with(linux_conf).returns(true)
      ParseConfig.expects(:new).with(linux_conf)
      Config.instance 
    end

    def test_linux_config_does_not_exist
      gem_conf = '/gem/conf'
      File.expects(:exists?).returns(false)
      File.expects(:join).returns(gem_conf)
      ParseConfig.expects(:new).with(gem_conf)
      Config.instance 
    end
    
    def teardown
      Mocha::Mockery.instance.stubba.unstub_all
    end
  end
end
