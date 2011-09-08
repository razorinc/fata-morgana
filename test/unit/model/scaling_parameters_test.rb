require 'test_helper'
require 'openshift-sdk/model/component'
require 'openshift-sdk/model/scaling_parameters'

module Openshift::SDK::Model
  class ScalingTest < Test::Unit::TestCase
    include ActiveModel::Lint::Tests

    def setup()
    end
    
    def model
      ScalingParameters.new
    end

    def test_init
      s = ScalingParameters.new
      assert_equal 1,s.min
      assert_equal -1,s.max
      assert_equal "+1",s.default_scale_by
      assert_equal "1--1-+1", s.generate_signature
    end

    def test_init_dedicatd
      s = ScalingParameters.new()
      s.from_descriptor_hash({"Min" => 2, "Max" => 7})
      assert_equal 2,s.min
      assert_equal 7,s.max
      assert_equal "+1",s.default_scale_by
      assert_equal "2-7-+1", s.generate_signature
    end
  end
end
