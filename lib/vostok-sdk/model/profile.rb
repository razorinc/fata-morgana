require 'rubygems'
require 'json'
require 'active_model'
require 'vostok-sdk/model/component'

module Vostok
  module SDK
    class Profile
      include ActiveModel::Validations
      include ActiveModel::Serializers::JSON
      include ActiveModel::Serializers::Xml
      validates_presence_of :name, :components, :connections
      attr_accessor :name, :components, :connections

      def attributes
        @attributes ||= {'name' => nil, 'components' => nil, 'connections' => nil}
      end
      
      def attributes=(attr)
        attr.each do |name,value|
          send("#{name}=",value)
        end
      end

      def self.load_descriptor(name,json_data,cartridge)
        p = Profile.new
        p.name=name
        
        p.components = {}
        if json_data.has_key?("components")
          json_data["components"].each{|k,v|
            p.components[k] = Component.load_descriptor(k,v)
          }
        else
          feature_name = cartridge.provides_feature[0]
          p.components[feature_name] = Component.load_descriptor(feature_name,json_data)
        end
        
        p
      end
    end
  end
end