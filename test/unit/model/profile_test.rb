require 'test_helper'

module Openshift::SDK::Model
  class ProfileTest < Test::Unit::TestCase
    def test_load_descriptor
      component = Component.new
      component.stubs(:guid).returns("1234")
      Component.expects(:load_descriptor).returns(component)
      
      cartridge = Cartridge.new
      cartridge.expects(:provides_feature).returns(["some_feature"])
      json = JSON.parse("{}")
      
      profile = Profile.load_descriptor("name", json, cartridge)
      assert_not_nil profile
      assert_equal '1234', profile.components['some_feature']
      assert_equal 'name', profile.name
    end
    
    def test_load_descriptor_with_components
      component = Component.new
      component.stubs(:guid).returns("1234")
      Component.expects(:load_descriptor).returns(component)
      
      cartridge = Cartridge.new
      
      json = JSON.parse('{"components":{"some_feature":""}}')
      
      profile = Profile.load_descriptor("name", json, cartridge)
      assert_not_nil profile
      assert_equal '1234', profile.components['some_feature']
      assert_equal 'name', profile.name
    end
  end
end