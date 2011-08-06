require 'rubygems'
require 'active_model'
require 'vostok-sdk/model/model'

module Vostok
  module SDK
    class ConnectionEndpoint < Model
      validates_presence_of :group_name, :component_name, :connector_name
      ds_attr_accessor :group_name, :component_name, :connector_name
      
      def initialize(group_name, component_name, connector_name)
        @group_name, @component_name, @connector_name= group_name, component_name, connector_name
      end
      
      def attributes
        @attributes ||= {"group_name" => nil, "component_name" => nil, "connector_name" => nil}
      end
      
      def attributes=(attr)
        attr.each do |name,value|
          send("#{name}=",value)
        end
      end
      
    end
  end
end