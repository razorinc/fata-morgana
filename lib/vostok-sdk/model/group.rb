require 'rubygems'
require 'json'
require 'active_model'
require 'vostok-sdk/config'
require 'vostok-sdk/model/component_instance'

module Vostok
  module SDK
    class Group
      include ActiveModel::Validations
      include ActiveModel::Serializers::JSON
      include ActiveModel::Serializers::Xml
      validates_presence_of :name, :components
      attr_accessor :name, :components
      
      def attributes
        @attributes ||= {'name' => nil, 'components' => nil}
      end
      
      def attributes=(attr)
        attr.each do |name,value|
          send("#{name}=",value)
        end
      end

      def self.load_descriptor(name,json_data,app_descriptor)
        g = Group.new
        g.name=name
        
        g.components = {}
        if json_data["components"]
          json_data["components"].each{|k,v|
            g.components[k] = ComponentInstance.load_descriptor(k,v)
          }
        else
          app = app_descriptor.app
          app.requires_feature.each{ |feature|
            f_inst, f_dep_cmap = ComponentInstance.from_app_dependency(feature)
            g.components.merge!(f_dep_cmap)
          }
        end
        g
      end
    end
  end
end