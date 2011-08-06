require 'rubygems'
require 'active_model'

module Vostok
  module SDK
    class Connection
      extend ActiveModel::Naming
      include ActiveModel::Validations
      include ActiveModel::Serializers::JSON
      include ActiveModel::Serializers::Xml
      validates_presence_of :name, :pub, :sub      
      attr_accessor :name, :pub, :sub      

      
      def initialize(name,pub,sub)
        @name, @pub, @sub = name, pub, sub
      end
      
      def attributes
        @attributes ||= {'name' => 'nil', 'pub' => nil, 'sub' => nil}
      end
      
      def attributes=(attr)
        attr.each do |name,value|
          send("#{name}=",value)
        end
      end
    end
  end
end