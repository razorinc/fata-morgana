require 'test_helper'

module Openshift::SDK::Model
  class ConnectorTest < Test::Unit::TestCase
    include ActiveModel::Lint::Tests

    def model
      Connector.new("conn_name")
    end

    def test_from_descriptor_hash
      c = Connector.new("conn_name")
      c.from_descriptor_hash( {"Type" => "FILESYSTEM:doc-root", "Required" => "true" } )
      assert_not_nil c
      assert_not_nil c.required
      assert_equal true,c.required
      assert_equal "conn_name",c.name
      assert_equal "FILESYSTEM:doc-root",c.type
    end
    
    def test_from_descriptor_hash_default
      c = Connector.new("conn_name")
      c.from_descriptor_hash( {"Type" => "FILESYSTEM:doc-root"} )
      assert_not_nil c
      assert_not_nil c.required
      assert_equal false,c.required
      assert_equal "conn_name",c.name
      assert_equal "FILESYSTEM:doc-root",c.type
    end    

    def test_json
      File.expects(:join).at_least_once
      c = Connector.new("conn_name")
      c.from_descriptor_hash( {"Type" => "FILESYSTEM:doc-root", "Required" => "true"} )
      
      data = c.to_json
      #print data, "\n"
      c = Connector.new.from_json data
      assert_not_nil c
      assert_not_nil c.required
      assert_equal true,c.required
      assert_equal "conn_name",c.name
      assert_equal "FILESYSTEM:doc-root",c.type
    end

    def test_xml
      File.expects(:join).at_least_once
      c = Connector.new("conn_name")
      c.from_descriptor_hash( {"Type" => "FILESYSTEM:doc-root", "Required" => "true"} )
      
      data = c.to_xml
      #print data, "\n"
      c = Connector.new.from_xml data
      assert_not_nil c
      assert_not_nil c.required
      assert_equal true,c.required
      assert_equal "conn_name",c.name
      assert_equal "FILESYSTEM:doc-root",c.type
    end
  end
end
