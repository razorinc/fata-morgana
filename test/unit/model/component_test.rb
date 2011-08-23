require 'test_helper'

module Openshift::SDK::Model
  class ComponentTest < Test::Unit::TestCase
    include ActiveModel::Lint::Tests

    def model
      Component.new
    end
    
    def setup
      @c = Component.new "feat1", {"connectors" => { "subscribes" => { "c1" => {"type" => "FILESYSTEM:DOC_ROOT", "required" => "true"}}}}
    end

    def test_init_without_connectors
      c = Component.new "feat1", {"connector" => {}}
      assert_not_nil c
      assert_equal "feat1", c.feature
      assert_equal({}, c.publishes)
      assert_equal({}, c.subscribes)
    end

    def test_init
      assert_not_nil @c
      assert_equal "feat1", @c.feature
      assert_equal({}, @c.publishes)
      assert_equal(1, @c.subscribes.size)
    end

    def test_json
      File.expects(:join).at_least_once
      data = @c.to_json
      c = Component.new.from_json data
      assert_not_nil c
      assert_equal "feat1", c.feature
      assert_equal({}, c.publishes)
      assert_equal(1, c.subscribes.size)
      assert_equal(Connector,c.subscribes.values[0].class)
    end
    
    def test_xml
      File.expects(:join).at_least_once
      data = @c.to_xml
      c = Component.new.from_xml data
      assert_not_nil c
      assert_equal "feat1", c.feature
      assert_equal({}, c.publishes)
      assert_equal(1, c.subscribes.size)
      assert_equal(Connector,c.subscribes.values[0].class)
    end
   
    def test_yaml
      File.expects(:join).at_least_once
      data = @c.to_yaml
      c = YAML.load(data)
      assert_not_nil c
      assert_equal "feat1", c.feature
      assert_equal({}, c.publishes)
      assert_equal(1, c.subscribes.size)
      assert_equal(Connector,c.subscribes.values[0].class)
    end     
  end
end
