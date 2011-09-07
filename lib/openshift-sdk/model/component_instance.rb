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
require 'openshift-sdk/model/cartridge_instance'
require 'openshift-sdk/model/feature_cartridge_cache'

module Openshift::SDK::Model
  class ComponentInstance < OpenshiftModel
    validates_presence_of :component
    ds_attr_accessor :name, :component, :cartridge_instances
    
    def initialize(name=nil, component_def=nil)
      self.name = name
      self.component = component_def
      self.cartridge_instances = {}
      self.resolve_references
    end
    
    #for XML, JSON serialization
    def attributes
      {"name"=> @name, "component" => self.component}
    end

    def resolve_dependency(dependency)
      feature, profile_name = dependency.split(":")
      if profile_name
        # feature is actually a cartridge name now, because profile is provided
        cart_list = Cartridge.list_installed
        cart_list.each { |cart|
          return [cart,profile_name] if cart.name == feature
        }
        raise "Cartridge dependency #{dependency} not resolved. Cartridge not installed?"
      else
        cart_list = Cartridge.what_provides(feature)
        if cart_list.nil? or cart_list.length==0
          raise "Cartridge dependency #{dependency} not resolved. Cartridge not installed?"
        end
        cartridge = cart_list[0]
        profile_name = cartridge.get_profile_from_feature(feature)
        return [cartridge,profile_name]
      end
    end

    def resolve_references
      if self.component.nil? 
        raise "Component not defined for instance #{name}"
      end

      dependencies = self.component.dependencies
      dependencies.each do |dependency|
        cartridge, profile_name = resolve_dependency(dependency)
        cart_instance = CartridgeInstance.new(self, profile_name, cartridge)
        self.cartridge_instances[cartridge.name + ":" + profile_name] = cart_instance
        cart_instance.cartridge.descriptor.resolve_references
      end
    end
  end
end
