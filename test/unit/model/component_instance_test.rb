require 'test_helper'

module Openshift::SDK::Model
  class ComponentInstanceTest < Test::Unit::TestCase
    include ActiveModel::Lint::Tests

    def model
      ComponentInstance.new
    end

    def test_json
      File.expects(:join).at_least_once
      c = ComponentInstance.new("inst1", "comp1")
      data = c.to_json
      c = ComponentInstance.new.from_json data
      assert_not_nil c
      assert_equal "inst1", c.name
      assert_equal "comp1", c.component
    end
    
    def test_xml
      File.expects(:join).at_least_once
      c = ComponentInstance.new("inst1", "comp1")
      data = c.to_xml
      c = ComponentInstance.new.from_xml data
      assert_not_nil c
      assert_equal "inst1", c.name
      assert_equal "comp1", c.component
    end
  end
end