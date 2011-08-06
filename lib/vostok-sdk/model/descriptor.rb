require 'rubygems'
require 'json'
require 'active_model'
require 'vostok-sdk/config'
require 'vostok-sdk/model/cartridge'
require 'vostok-sdk/model/profile'

module Vostok
  module SDK
    class Descriptor
      include ActiveModel::Validations
      include ActiveModel::Serializers::JSON
      include ActiveModel::Serializers::Xml
      validates_presence_of :profiles, :cartridge
      attr_accessor :profiles, :cartridge
      
      def attributes
        @attributes ||= {'profiles' => nil, 'cartridge' => nil}
      end
      
      def attributes=(attr)
        attr.each do |name,value|
          send("#{name}=",value)
        end
      end

      def self.load_descriptor(cartridge)
        d = Descriptor.new
        d.cartridge = cartridge
        f = File.open("#{cartridge.package_path}/vostok/descriptor.json")
        
        json_data = JSON.parse(f.read)
        d.profiles = {}
        if json_data.has_key?("profiles")
          json_data["profiles"].each{|k,v|
            d.profiles[k] = Profile.load_descriptor(k,v,cartridge)
          }
        else
          d.profiles["default"] = Profile.load_descriptor("default",json_data,cartridge)
        end
        
        d
      end
    end
  end
end
