require 'test_helper'

module Openshift::SDK::Model
  class ConnectorTest < Test::Unit::TestCase
    include ActiveModel::Lint::Tests

    def model
      Connector.new("conn_name",:subscriber,{"type" => "FILESYSTEM:DOC_ROOT", "required" => "false"})
    end

    def test_init_without_required
      c = Connector.new("conn_name",:subscriber,{"type" => "FILESYSTEM:DOC_ROOT"})
      assert_not_nil c
      assert_not_nil c.required
      assert_equal false,c.required
      assert_equal "conn_name",c.name
      assert_equal "FILESYSTEM:DOC_ROOT",c.type
      assert_equal :subscriber,c.pubsub
    end

    def test_init
      c = Connector.new("conn_name",:subscriber,{"type" => "FILESYSTEM:DOC_ROOT", "required" => "true"})
      assert_not_nil c
      assert_not_nil c.required
      assert_equal true,c.required
      assert_equal "conn_name",c.name
      assert_equal "FILESYSTEM:DOC_ROOT",c.type
      assert_equal :subscriber,c.pubsub
    end

    def test_json
      File.expects(:join).at_least_once
      c = Connector.new("conn_name",:subscriber,{"type" => "FILESYSTEM:DOC_ROOT", "required" => "true"})
      json_data = c.to_json
      #print json_data, "\n"
      c = Connector.new.from_json json_data
      assert_not_nil c
      assert_not_nil c.required
      assert_equal true,c.required
      assert_equal "conn_name",c.name
      assert_equal "FILESYSTEM:DOC_ROOT",c.type
      assert_equal :subscriber,c.pubsub
    end

    def test_xml
      File.expects(:join).at_least_once
      c = Connector.new("conn_name",:subscriber,{"type" => "FILESYSTEM:DOC_ROOT", "required" => "true"})
      data = c.to_xml
      #print data, "\n"
      c = Connector.new.from_xml data
      assert_not_nil c
      assert_not_nil c.required
      assert_equal true,c.required
      assert_equal "conn_name",c.name
      assert_equal "FILESYSTEM:DOC_ROOT",c.type
      assert_equal :subscriber,c.pubsub
    end

    def test_yaml
      File.expects(:join).at_least_once
      c = Connector.new("conn_name",:subscriber,{"type" => "FILESYSTEM:DOC_ROOT", "required" => "true"})
      data = c.to_yaml
      #print data, "\n"
      c = YAML.load(data)
      assert_not_nil c
      assert_not_nil c.required
      assert_equal true,c.required
      assert_equal "conn_name",c.name
      assert_equal "FILESYSTEM:DOC_ROOT",c.type
      assert_equal :subscriber,c.pubsub
    end

  end
end
