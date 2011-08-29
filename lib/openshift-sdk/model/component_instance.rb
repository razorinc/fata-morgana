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
require 'openshift-sdk/model/feature_cartridge_cache'

module Openshift::SDK::Model
  class ComponentInstance < OpenshiftModel
    validates_presence_of :feature, :cartridge, :component, :profile_name, :group_name
    ds_attr_accessor :feature, :cartridge, :component, :profile_name, :dependency_instances, :component_group_name, :group_name
    
    def initialize(guid=nil,descriptor_data=nil)
      self.dependency_instances = {}
      return if guid.nil?
      
      self.guid = guid
      self.feature = descriptor_data["feature"]
      cartridge_name = descriptor_data["cartridge_name"]
      cartridge = nil
      if cartridge_name
        cartridge = Cartridge.from_rpm(cartridge_name)
      else
        cartridge = FeatureCartridgeCache.instance.what_provides(self.feature)[0]
      end
      cart_descriptor = cartridge.descriptor
      self.profile_name = descriptor_data["profile_name"] || cart_descriptor.profiles.keys[0]
      profile = cart_descriptor.profiles[self.profile_name]
      profile.groups.each do |gname, group|
        self.component = group.components[feature]
        break if self.component
      end
      component_guid = self.component.guid
      self.component_guid = component_guid
      self.cartridge = cartridge
      self.gen_uuid
    end
    
    #for XML, JSON serialization
    def attributes
      {"feature"=> @feature, "cartridge"=>self.cartridge, "component" => self.component,
        "profile_name" => profile_name}
    end
    
    # Searches for a required feature in all cartridges. If a cartridge with
    # the required feature is found then it loops through all profiles and
    # finds one which provides the feature. It then instantiates all components
    # that are part of that profile.
    def self.component_instance_for_feature(feature, profile=nil)
      cartridges = FeatureCartridgeCache.instance.what_provides(feature)
#print feature, cartridges, "\n"
      components = {}
      cartridges.each do |cartridge|
        next if cartridge.nil?
        cart_descriptor = cartridge.descriptor
        next if cart_descriptor.nil?
        cart_descriptor.profiles.each do |profile_name, profile_inst|
          next if profile and profile_name != profile
          
          profile_provides_feature = false
          profile_inst.groups.each do |group_name, group|
            if group.components[feature]
              #this profile matches required feature so 
              #instantiate all components within the profile
              profile_provides_feature = true
              break
            end
          end
          
          if profile_provides_feature
            profile_inst.groups.each do |group_name, group|
              group.components.each do |cname, component|
                cinst = ComponentInstance.new
                cinst.gen_uuid
                cinst.cartridge = cartridge
                cinst.feature = component.feature
                cinst.component = component
                cinst.profile_name = profile_name
                cinst.component_group_name = group_name
                components[cinst.guid]=cinst
              end
            end
            
            dependency_instances = {}
            cartridge.requires_feature.each do |req_feature|
              dependency_instances.merge! component_instance_for_feature(req_feature)
            end
            components.each do |cname,cinst|
              cinst.dependency_instances = dependency_instances.keys
            end
            components.merge! dependency_instances
            
            break
          end
        end
      end
        
      components
    end
  end
end
