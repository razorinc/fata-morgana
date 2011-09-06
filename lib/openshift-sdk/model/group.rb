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
#--

require 'rubygems'
require 'json'
require 'active_model'
require 'openshift-sdk/config'
require 'openshift-sdk/model/model'
require 'openshift-sdk/model/component'
require 'openshift-sdk/model/component_instance'
require 'openshift-sdk/model/scaling_parameters'
require 'openshift-sdk/utils/logger'

module Openshift::SDK::Model
  # == Component Group
  #
  # Defines a component group. All components within the group are run on the 
  # all nodes within a group. Scaling parameters also only apply to this level. 
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
  # [components] A hash map with all componnts that are part of the group
  # [nodes] A list of nodes that are part of the group
  # [scaling] Scaling parameters set for the group
  class Group < OpenshiftModel
    ds_attr_accessor :name,:components, :scaling, :reservations, :resolved_components_hash, :profile
    
    def initialize(name)
      self.name = name
      self.components = {}
      self.scaling = ScalingParameters.new
      self.reservations = []
      self.resolved_components_hash = {}
      self.profile = nil
    end
    
    def from_descriptor_hash(hash)
      component_instances = hash["Components"] if hash["Components"]
      case component_instances
        when Array
          component_instances.each { |comp| self.components[comp] = comp }
        when Hash
          self.components = component_instances
      end
      self.reservations = hash["Reservations"] if hash["Reservations"]
      if hash["Scaling"]
        scaling_will_change!
        self.scaling.from_descriptor_hash(hash["Scaling"])
      end
      self.resolve_references
    end
    
    def to_descriptor_hash
      {
        "Components" => self.components,
        "Reservations" => self.reservations,
        "Scaling" => self.scaling.to_descriptor_hash
      }
    end

    def resolve_references(component_hash=nil)
      raise "Empty parent profile" if self.profile.nil?
      component_defs_hash = self.profile.components

      comphash = component_hash || self.components
      comphash.keys.each { |inst_name|
        comp_name = comphash[inst_name]
        if component_defs_hash[comp_name]
          self.resolved_components_hash[inst_name] = 
                  ComponentInstance.new(inst_name, component_defs_hash[comp_name])
        else
          # FIXME : resolve this by treating the comp_name as a feature
          #         .. add a component by that feature-cartridge pair
          raise "Unresolved component #{comp_name}"
        end
      }
      # unresolved_instances_count = 
      #       self.resolved_components_hash.length - self.components.length
    end

    def add_component_instance(component_name, instance_name=nil)
      self.components = {} if self.components
      instance_name = component_name unless instance_name
      self.components[instance_name] = component_name
      local_resolution_hash = {}
      local_resolution_hash[instance_name] = component_name
      self.resolve_references(local_resolution_hash)
    end
  end
end
