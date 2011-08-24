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

require 'rubygems'
require 'active_model'
require 'openshift-sdk/model/model'
require 'openshift-sdk/model/descriptor'
require 'openshift-sdk/model/cartridge'
require 'openshift-sdk/model/component_instance'

module Openshift
  module SDK
    module Model
      class ComponentInstance < OpenshiftModel
        validates_presence_of :name, :feature, :cartridge, :component, :profile_name
        ds_attr_accessor :name, :feature, :cartridge, :component, :profile_name, :dependency_instances
        
        def initialize
          @dependency_instances = {}
        end
        
        #for XML, JSON serialization
        def attributes
          {"name"=> @name, "feature"=> @feature, "cartridge"=>self.cartridge, "component" => self.component,
            "profile_name" => profile_name}
        end
        
        def self.from_app_dependency(feature)
          cartridge = Cartridge.what_provides(feature)[0]
          cart_descriptor = cartridge.descriptor
          profile_name = cart_descriptor.profiles.keys[0]
          profile = cart_descriptor.profiles[profile_name]
          group_name = profile.groups.keys[0]
          group = profile.groups[group_name]

          cmap = {}
          direct_deps = []
          group.components.each do |name,component|
            c = ComponentInstance.new
            c.feature = c.name = component.feature
            c.cartridge = cartridge
            c.component = component
            c.profile_name = profile_name
            cmap[c.name] = c
                           
            cartridge.requires_feature.each{ |f|
              f_inst, f_dep_cmap = ComponentInstance.from_app_dependency(f)
              c.dependency_instances[f] = {"group_name"=> group.name, "cinst_names" => f_inst}
              cmap.merge!(f_dep_cmap)
            }
            direct_deps.push(c.name)
          end

          return direct_deps, cmap
        end
        
        def self.load_descriptor(name,json_data)
          c = ComponentInstance.new
          c.name = name
          c.feature = json_data["feature"]
          cartridge_name = json_data["cartridge_name"]
          cartridge = nil
          if cartridge_name
            cartridge = Cartridge.from_rpm(cartridge_name)
          else
            cartridge = Cartridge.what_provides(c.feature)[0]  
          end
          cart_descriptor = cartridge.descriptor
          c.profile_name = json_data["profile_name"] || cart_descriptor.profiles.keys[0]
          component_guid = cart_descriptor.profiles[c.profile_name].components[c.feature]
          c.component_guid = component_guid
          c.cartridge = cartridge
  
          c
        end      
      end
    end
  end
end
