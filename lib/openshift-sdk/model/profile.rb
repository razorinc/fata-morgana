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
          c.user_defined = true
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
          g.user_defined = true
          g.profile = self
          g.from_descriptor_hash(group_hash)
        end
      else
        # create default group
        g = @groups["default"] = Group.new("default")
        g.profile = self
        g.from_descriptor_hash({})
        self.components.keys.each do |cname|
          g.add_component_instance(component_name=cname, instance_name=cname, resolve_reference=false, auto_generated=true)
        end
        g.scaling.from_descriptor_hash(hash["Scaling"]) if hash["Scaling"]
      end
      
      if hash["Connections"]
        connections_will_change!
        hash["Connections"].each do |conn_name, conn_hash|
          c = @connections[conn_name] = Connection.new(conn_name)
          c.user_defined = true
          c.profile = self
          c.from_descriptor_hash(conn_hash)
        end
      end
    end
    
    def to_descriptor_hash
      h = {}

      c = {}
      self.components.each do |comp_name, comp|
        if comp.user_defined
          c[comp_name] = comp.to_descriptor_hash
        else
          h.merge! comp.to_descriptor_hash
        end
      end
      
      g = {}
      self.groups.each do |group_name, group|
        if group.user_defined
          g[group_name] = group.to_descriptor_hash
        else
          h.merge! group.to_descriptor_hash
        end
      end
      
      cn = {}
      self.connections.each do |conn_name, conn|
        if conn.user_defined
          cn[conn_name] = conn.to_descriptor_hash
        else
          h.merge! conn.to_descriptor_hash
        end
      end
      
      h["Provides"] = self.provides if self.provides.length > 0
      h["Reservations"] = self.reservations if self.reservations.length > 0
      h["Property Overrides"] = self.property_overrides if self.property_overrides.length > 0
      h["Components"] = c if c.length > 0
      h["Groups"] = g if g.length > 0
      h["Connections"] = cn if cn.length > 0
      h
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
