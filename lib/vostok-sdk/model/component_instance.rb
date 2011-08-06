require 'rubygems'
require 'active_model'
require 'vostok-sdk/model/descriptor'
require 'vostok-sdk/model/cartridge'
require 'vostok-sdk/model/component_instance'

module Vostok
  module SDK
    class ComponentInstance
      include ActiveModel::Validations
      include ActiveModel::Serializers::JSON
      include ActiveModel::Serializers::Xml
      validates_presence_of :name, :feature, :cartridge, :component, :profile_name, :dependency_instances
      attr_accessor :name, :feature, :cartridge, :component, :profile_name, :dependency_instances
      
      def initialize
        @dependency_instances = {}
      end
      
      def attributes
        @attributes ||= {"name" => nil, "feature" => nil, "cartridge" => nil, 
          "component" => nil, "profile_name" => nil, "dependency_instances" => nil}
      end
      
      def attributes=(attr)
        attr.each do |name,value|
          send("#{name}=",value)
        end
      end
      
      def self.from_app_dependency(feature)
        cartridge = Cartridge.what_provides(feature)[0]
        cart_descriptor = Descriptor.load_descriptor(cartridge)
        profile_name = cart_descriptor.profiles.keys[0]
        
        cmap = {}
        direct_deps = []
        cart_descriptor.profiles[profile_name].components.each{ |k,v|
          c = ComponentInstance.new
          c.feature = c.name = v.feature
          c.cartridge = cartridge
          c.component = v
          c.profile_name = profile_name
          cmap[c.name] = c
          
          cartridge.requires_feature.each{ |f|
            f_inst, f_dep_cmap = ComponentInstance.from_app_dependency(f)
            c.dependency_instances[f] = f_inst
            cmap.merge!(f_dep_cmap)
          }
          direct_deps.push(c.name)
        }
        
        return direct_deps, cmap
      end
      
      def self.load_descriptor(name,json_data)
        c = ComponentInstance.new
        c.name = name
        c.feature = json_data["feature"]
        cartridge_name = json_data["cartridge_name"]
        if cartridge_name
          c.cartridge = Cartridge.from_rpm(cartridge_name)
        else
          c.cartridge = Cartridge.what_provides(c.feature)[0]  
        end
        cart_descriptor = Descriptor.load_descriptor(c.cartridge)
        c.profile_name = json_data["profile_name"] || cart_descriptor.profiles.keys[0]
        c.component = cart_descriptor.profiles[c.profile_name].components[c.feature]

        c
      end      
    end
  end
end