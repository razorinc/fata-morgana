require 'test_helper'

module Openshift::SDK::Model
  class ProfileTest < Test::Unit::TestCase
    include ActiveModel::Lint::Tests

    def model
      Profile.new
    end
    
    def test_descriptor
      p = Profile.new("prof1")
      p.from_descriptor_hash(
        {
          "Provides" => ["p1"],
          "Property Overrides" => ["prop1=abcd"],
           "Start-Order" => "abcd",
           "Dependencies" => [],
           "Publishes" => {},
           "Subscribes" => {},
           "Scaling" => {"Min" => 2},
         "Reservations" => ["MEM >= 500M"]
        })
    end
    
    def test_descriptor
      p = Profile.new("prof1")
      hash = {
        "Provides" => ["p1"],
        "Property Overrides" => ["prop1=abcd"],
         "Start-Order" => "abcd",
         "Dependencies" => [],
         "Publishes" => {},
         "Subscribes" => {},
         "Scaling" => {"Min" => 2},
         "Reservations" => ["MEM >= 500M"],
         "Foobar" => 1
      }
      assert_raise(RuntimeError){p.from_descriptor_hash(hash)}
    end
    
    def test_descriptor_minimal1
      p = Profile.new("prof1")
      p.from_descriptor_hash(
        {
          "Components" => {
            "comp1" => {"Subscribes" => { "c1" => {"Type" => "FILESYSTEM:DOC_ROOT"}}}
          }
        })
      assert_equal "prof1", p.name
      assert_not_nil p.components["comp1"]
      assert_not_nil p.groups["default"]
      assert_not_nil p.groups["default"].components["comp1"]
      assert_equal "comp1", p.groups["default"].components["comp1"]
    end
    
    def test_descriptor_minimal2
      p = Profile.new("prof1")
      p.from_descriptor_hash(
        {
          "Subscribes" => { "c1" => {"Type" => "FILESYSTEM:DOC_ROOT"}}
        })
      assert_equal "prof1", p.name
      assert_not_nil p.components["default"]
      assert_not_nil p.groups["default"]
      assert_not_nil p.groups["default"].components["default"]
      assert_equal "default", p.groups["default"].components["default"]
    end

    def test_descriptor_reservations
      p = Profile.new("prof1")
      p.from_descriptor_hash(
        {
          "Components" => {
            "comp1" => {"Subscribes" => { "c1" => {"Type" => "FILESYSTEM:DOC_ROOT"}}}
          },
          "Reservations" => ["f1", "f2"]
        })
      assert_equal "prof1", p.name
      assert_equal 2, p.reservations.length
    end    
    
    def test_descriptor_provides1
      p = Profile.new("prof1")
      p.from_descriptor_hash(
        {
          "Components" => {
            "comp1" => {"Subscribes" => { "c1" => {"Type" => "FILESYSTEM:DOC_ROOT"}}}
          },
          "Provides" => "f1,f2"
        })
      assert_equal "prof1", p.name
      assert_equal 2, p.provides.length
    end
    
    def test_descriptor_provides2
      p = Profile.new("prof1")
      p.from_descriptor_hash(
        {
          "Components" => {
            "comp1" => {"Subscribes" => { "c1" => {"Type" => "FILESYSTEM:DOC_ROOT"}}}
          },
          "Provides" => ["f1", "f2"]
        })
      assert_equal "prof1", p.name
      assert_equal 2, p.provides.length
    end
    
    def test_descriptor_group1
      p = Profile.new("prof1")
      p.from_descriptor_hash(
        {
          "Components" => {
            "comp1" => {"Subscribes" => { "c1" => {"Type" => "FILESYSTEM:DOC_ROOT"}}},
            "comp2" => {"Publishes" => { "c1" => {"Type" => "FILESYSTEM:DOC_ROOT"}}}
          },
          "Groups" => {
            "g1" => {
              "Components" => {
                "cinst1" => "comp1",
                "cinst2" => "comp2"
              }
            }
          }
        })
      assert_equal "prof1", p.name
      assert_not_nil p.components["comp1"]
      assert_not_nil p.groups["g1"]
      assert_not_nil p.groups["g1"].components["cinst1"]
      assert_equal "comp1", p.groups["g1"].components["cinst1"]
    end
    
    def test_descriptor_connections
      p = Profile.new("prof1")
      p.from_descriptor_hash(
        {
          "Components" => {
            "comp1" => {"Subscribes" => { "c1" => {"Type" => "FILESYSTEM:DOC_ROOT"}}},
            "comp2" => {"Publishes" => { "c1" => {"Type" => "FILESYSTEM:DOC_ROOT"}}}
          },
          "Groups" => {
            "g1" => {
              "Components" => {
                "cinst1" => "comp1",
                "cinst2" => "comp2"
              }
            }
          },
          "Connections" => {
            "conn1" => { "Components" => ["cinst1","cinst2"]}
          }
        })
      assert_equal "prof1", p.name
      assert_equal 2, p.connections["conn1"].components.size
    end
    
    def teardown
      Mocha::Mockery.instance.stubba.unstub_all
    end
  end
end