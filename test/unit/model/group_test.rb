require 'test_helper'
require 'openshift-sdk/model/component'
require 'openshift-sdk/model/scaling_parameters'

module Openshift::SDK::Model
  class GroupTest < Test::Unit::TestCase
    include ActiveModel::Lint::Tests

    def model
      Group.new
    end
    
    def test_descriptor
      g = Group.new("group1")
      assert_raise(RuntimeError){g.from_descriptor_hash({"Components" => ["comp1"], "Reservations" => "MEM >= 500M", "Foobar" => 1})}
    end

    def test_init_without_scaling
      g = Group.new("group1")
      g.from_descriptor_hash({"Components" => ["comp1"], "Reservations" => "MEM >= 500M"})
      assert_not_nil g
      assert_equal 1,g.scaling.min
      assert_equal -1,g.scaling.max
      assert_equal "+1",g.scaling.default_scale_by
      assert_equal 1,g.components.size
      assert_equal "MEM >= 500M", g.reservations
    end

    def test_init
      g = Group.new("group1")
      g.from_descriptor_hash({"Components" => ["comp1"], "Reservations" => "MEM >= 500M", "Scaling" => {"Min" => 2}})
      assert_not_nil g
      assert_equal 2,g.scaling.min
      assert_equal -1,g.scaling.max
      assert_equal "+1",g.scaling.default_scale_by
      assert_equal 1,g.components.size
      assert_equal "MEM >= 500M", g.reservations
    end

    def test_json
      g = Group.new("group1")
      g.from_descriptor_hash({"Components" => ["comp1"], "Reservations" => "MEM >= 500M"})
      
      data = g.to_json
      #print "#{data}\n"
      g = Group.new.from_json data
      assert_not_nil g
      assert_equal "+1",g.scaling.default_scale_by
      assert_equal 1,g.scaling.min
      assert_equal -1,g.scaling.max
      assert_equal 1,g.components.size
      assert_equal "MEM >= 500M", g.reservations
    end

    def test_xml
      g = Group.new("group1")
      g.from_descriptor_hash({"Components" => ["comp1"], "Reservations" => "MEM >= 500M"})      
      data = g.to_xml
      #print "#{data}\n"
      g = Group.new.from_xml data
      assert_not_nil g
      assert_equal 1,g.scaling.min
      assert_equal -1,g.scaling.max
      assert_equal "+1",g.scaling.default_scale_by
      assert_equal 1,g.components.size
      assert_equal "MEM >= 500M", g.reservations
    end
  end
end
