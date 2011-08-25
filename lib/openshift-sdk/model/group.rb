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
  # == Overall location within descriptor
  #
  #      |
  #      +-Profile
  #           |
  #           +-Group
  #           |   |
  #           |   +-Scaling
  #           |   |
  #           |   +-Component
  #           |         |
  #           |         +-Connector
  #           |
  #           +-Connection
  #               |
  #               +-*ConnectionEndpoint*
  #
  # == Properties
  # 
  # [name] The name of the group
  # [components] A hash map with all componnts that are part of the group
  # [nodes] A list of nodes that are part of the group
  # [scaling] Scaling parameters set for the group
  class Group < OpenshiftModel
    validates_presence_of :name, :components
    ds_attr_accessor :name, :components, :nodes, :scaling
    
    def initialize(name=nil, descriptor_data={},cartridge=nil)
      self.name = name
      self.components = {}
      self.scaling = ScalingParameters.new(descriptor_data["scaling"] || {})
      self.nodes = []
      return unless descriptor_data.keys.size > 0
        
      if cartridge.class == Cartridge
        if descriptor_data["components"]
          descriptor_data["components"].each{|feature,comp_hash|
            @components[feature] = Component.new(feature,comp_hash)
          }
        else
          unless cartridge.nil?
            cart_features = cartridge.provides_feature
            cart_features.each do |feature|
              feature = feature[/[^ =(]*/]
              @components[feature] = Component.new(feature,descriptor_data)
            end
          end
        end
      else
        descriptor_data["components"].each{|comp_name,comp_hash|
          @components[comp_name] = ComponentInstance.new(comp_name,comp_hash)
        }
      end 
    end
    
    def components=(vals)
      @components = {}
      return if vals.class != Hash
      vals.keys.each do |name|
        next if name.nil?
        if vals[name].class == Hash
          @components[name] = Component.new
          @components[name].attributes=vals[name]
        else
          @components[name] = vals[name]
        end
      end
    end
    
    def scaling=(val)
      if val.class == Hash
        @scaling=ScalingParameters.new
        @scaling.attributes=val
      else
        @scaling = val        
      end
    end
    
    def signature
      @signature ||= @scaling.generate_signature
    end
  end
end
