require 'rubygems'
require 'active_model'

module Vostok
  module SDK
    class ConnectionEndpoint
      extend ActiveModel::Naming
      include ActiveModel::Validations
      include ActiveModel::Serializers::JSON
      include ActiveModel::Serializers::Xml
      validates_presence_of :group_name, :component_name, :connector_name
      attr_accessor :group_name, :component_name, :connector_name
      
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