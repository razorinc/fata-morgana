require 'test_helper'

module Openshift::SDK::Model
  class ComponentTest < Test::Unit::TestCase
    include ActiveModel::Lint::Tests

    def model
      Component.new
    end
    
    def setup
      @c = Component.new "comp1"
      @c.from_descriptor_hash({"Subscribes" => { "c1" => {"Type" => "FILESYSTEM:DOC_ROOT", "Required" => "true"}}, "Publishes" => { "c1" => {"Type" => "FILESYSTEM:DOC_ROOT", "Required" => "true"}}, "Dependencies" => "www-static"})
    end

    def test_extra_param
      c = Component.new "comp1"
      assert_raise(RuntimeError){c.from_descriptor_hash({"Subscribes" => { "c1" => {"Type" => "FILESYSTEM:DOC_ROOT", "Required" => "true"}}, "Foobar" => 1})}
    end

    def test_init_without_connectors
      c = Component.new "comp1"
      @c.from_descriptor_hash({})
      assert_not_nil c
      assert_equal "comp1", c.name
      assert_equal({}, c.publishes)
      assert_equal({}, c.subscribes)
    end

    def test_init
      assert_not_nil @c
      assert_equal "comp1", @c.name
      assert_equal(1, @c.publishes.size)
      assert_equal(1, @c.subscribes.size)
    end

    def test_json
      File.expects(:join).at_least_once
      data = @c.to_json
      c = Component.new.from_json data
      assert_not_nil c
      assert_equal "comp1", c.name
      assert_equal(1, c.publishes.size)
      assert_equal(1, c.subscribes.size)
      assert_equal(Connector,c.subscribes.values[0].class)
    end
    
    def test_xml
      File.expects(:join).at_least_once
      data = @c.to_xml
      c = Component.new.from_xml data
      assert_not_nil c
      assert_equal "comp1", c.name
      assert_equal(1, c.publishes.size)
      assert_equal(1, c.subscribes.size)
      assert_equal(Connector,c.subscribes.values[0].class)
    end
    
    def teardown
      Mocha::Mockery.instance.stubba.unstub_all
    end
  end
end