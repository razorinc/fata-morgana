require 'test_helper'
require 'openshift-sdk/model/component'
require 'openshift-sdk/model/scaling_parameters'

module Openshift::SDK::Model
  class GroupTest < Test::Unit::TestCase
    include ActiveModel::Lint::Tests

    def setup()
    end
    
    def model
      ScalingParameters.new
    end

    def test_init
      s = ScalingParameters.new
      assert_equal 1,scaling.min
      assert_equal -1,scaling.max
      assert_equal "+1",scaling.default_scale_by
      assert_equal false,scaling.requires_dedicated
      assert_equal "1--1-false", s.generate_signature
    end

    def test_init_dedicatd
      Time.any_instance.expects(:nsec).returns(12345)
      s = ScalingParameters.new({"min" => 2, "max" => 7, "requires_dedicated" => "true"})
      assert_equal 2,s.min
      assert_equal 7,s.max
      assert_equal "+1",s.default_scale_by
      assert_equal true,s.requires_dedicated
      assert_equal "2-7-12345", s.generate_signature
      Time.any_instance.expects(:nsec).returns(12346)
      assert_equal "2-7-12346", s.generate_signature
    end
  end
end
