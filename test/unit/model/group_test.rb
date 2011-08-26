require 'test_helper'
require 'openshift-sdk/model/component'
require 'openshift-sdk/model/scaling_parameters'

module Openshift::SDK::Model
  class GroupTest < Test::Unit::TestCase
    include ActiveModel::Lint::Tests

    def setup()
      FeatureCartridgeCache.expects(:instance).at_least_once.returns(FeatureCartridgeCache.new)
      ComponentInstance.any_instance.expects(:initialize).at_least_once.returns(nil)
    end
    
    def model
      Group.new
    end

    def test_init_without_scaling
      g = Group.new("group1",{ "components" => { "feat1" => {} }})
      assert_not_nil g
      assert_equal 1,g.scaling.min
      assert_equal -1,g.scaling.max
      assert_equal "+1",g.scaling.default_scale_by
      assert_equal false,g.scaling.requires_dedicated
      assert_equal 1,g.components.keys.size
      assert_equal "1--1-false", g.signature
    end

    def test_init
      Time.any_instance.expects(:nsec).returns(12345)
      g = Group.new("group1",{ "components" => { "feat1" => {} }, "scaling" => { "min" => 2, "max" => 7, "requires_dedicated" => "true"}})
      assert_not_nil g
      assert_equal 2,g.scaling.min
      assert_equal 7,g.scaling.max
      assert_equal "+1",g.scaling.default_scale_by
      assert_equal true,g.scaling.requires_dedicated
      assert_equal 1,g.components.keys.size
      assert_equal "2-7-12345", g.signature
      Time.any_instance.expects(:nsec).returns(12346)
      assert_equal "2-7-12345", g.signature
    end

    def test_json
      File.expects(:join).at_least_once
      g = Group.new("group1",{ "components" => { "feat1" => {} }})
      data = g.to_json
      g = Group.new.from_json data
      assert_not_nil g
      assert_equal ScalingParameters,g.scaling.class
      assert_equal ComponentInstance,g.components["feat1"].class
    end

    def test_xml
      File.expects(:join).at_least_once
      g = Group.new("group1",{ "components" => { "feat1" => {} }})
      data = g.to_xml
      g = Group.new.from_xml data
      assert_not_nil g
      assert_equal ScalingParameters,g.scaling.class
      assert_equal ComponentInstance,g.components["feat1"].class
    end

    def test_yaml
      File.expects(:join).at_least_once
      g = Group.new("group1",{ "components" => { "feat1" => {} }})
      data = g.to_yaml
      g = YAML.load(data)
      assert_not_nil g
      assert_equal ScalingParameters,g.scaling.class
      assert_equal ComponentInstance,g.components["feat1"].class
    end
  end
end
