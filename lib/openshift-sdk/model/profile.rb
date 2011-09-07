#--
# Copyright 2010 Red Hat, Inc.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#++

require 'rubygems'
require 'json'
require 'active_model'
require 'openshift-sdk/model/model'
require 'openshift-sdk/model/group'
require 'openshift-sdk/model/component_instance'
require 'openshift-sdk/model/connection'
require 'openshift-sdk/model/connection_endpoint'

module Openshift::SDK::Model
  # == Profile
  #
  # Defines a cartridge or application profile. 
  #
  # == Overall descriptor
  #   Descriptor
  #      |
  #      +-Reserviations
  #      |
  #      +-Profile
  #           |
  #           +-Provides
  #           |
  #           +-Reserviations
  #           |
  #           +-ComponentDefs
  #           |    |
  #           |    +-Connector
  #           |    |
  #           |    +-Dependencies
  #           |
  #           +-Groups
  #           |   |
  #           |   +-Reserviations
  #           |   |
  #           |   +-Scaling
  #           |   |
  #           |   +-ComponentInstances
  #           |
  #           +-Connections
  #           |   |
  #           |   +-Endpoints
  #           |
  #           +-PropertyOverrides
  #
  # == Properties
  # 
  # [name] The name of the group
  # [groups] A hash map with all groups for this profile
  class Profile < OpenshiftModel
    validates_presence_of :name, :groups
    ds_attr_accessor :name, :provides, :reservations, :components, :groups, :connections, :property_overrides
    
    def initialize(name=nil)
      self.name = name
      @provides = []
      @reservations = []
      @components = {}
      @groups = {}
      @connections = {}
      @property_overrides = []
    end
    
    def resolve_references
      self.groups.each do |group_name, group|
        group.resolve_references
      end
      self.connections.each do |conn_name, conn|
        conn.resolve_references
      end
    end
    
    def from_descriptor_hash(hash,inherited_dependencies=nil)
      if hash["Provides"]
        if hash["Provides"].class == Array
          self.provides = hash["Provides"]
        else
          self.provides = hash["Provides"].split(",")
        end
      end
      self.reservations = hash["Reservations"] || []
      self.property_overrides = hash["Property Overrides"] || []
      components_will_change!
      if hash["Components"]
        hash["Components"].each do |component_name, component_hash|
          c = @components[component_name] = Component.new(component_name)
          c.from_descriptor_hash(component_hash,inherited_dependencies)
        end
      else
        deps = hash["Dependencies"]
        if hash["Dependencies"] or hash["Publishes"] or hash["Subscribes"]
          c = @components["default"] = Component.new("default")
          c.from_descriptor_hash(hash,inherited_dependencies)
        else
          c = @components["default"] = Component.new("default")
          c.from_descriptor_hash({},inherited_dependencies)
        end
      end
      
      groups_will_change!
      if hash["Groups"]
        hash["Groups"].each do |group_name, group_hash|
          g = @groups[group_name] = Group.new(group_name)
          g.profile = self
          g.from_descriptor_hash(group_hash)
        end
      else
        # create default group
        g = @groups["default"] = Group.new("default")
        g.profile = self
        g.from_descriptor_hash({})
        self.components.keys.each do |cname|
          g.add_component_instance(cname)
        end
        g.scaling.from_descriptor_hash(hash["Scaling"]) if hash["Scaling"]
      end
      
      if hash["Connections"]
        connections_will_change!
        hash["Connections"].each do |conn_name, conn_hash|
          c = @connections[conn_name] = Connection.new(conn_name)
          c.profile = self
          c.from_descriptor_hash(conn_hash)
        end
      end
    end
    
    def to_descriptor_hash
      c = {}
      self.components.each do |comp_name, comp|
        c[comp_name] = comp.to_descriptor_hash
      end
      
      g = {}
      self.groups.each do |group_name, group|
        g[group_name] = group.to_descriptor_hash
      end
      
      cn = {}
      self.connections.each do |conn_name, conn|
        cn[conn_name] = conn.to_descriptor_hash
      end
      
      {
        "Provides" => self.provides,
        "Reservations" => self.reservations,
        "Property Overrides" => self.property_overrides,
        "Components" => c,
        "Groups" => g,
        "Connections" => cn
      }
    end

    def get_all_component_instances
      return_list = []
      self.groups.each { |gname, group|
        group.resolved_components.each { |comp_name, comp|
          return_list.push(comp)
        }
      }
      return_list
    end

  end
end
