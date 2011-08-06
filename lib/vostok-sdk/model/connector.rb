require 'rubygems'
require 'active_model'
require 'vostok-sdk/model/model'

module Vostok
  module SDK
    class Connector < Model
      validates_presence_of :type, :pubsub, :name, :required
      ds_attr_accessor :type, :pubsub, :name, :required
      
      def self.load_descriptor(id,json_data, pubsub)
        c = Connector.new
        c.type = json_data['type'] if pubsub == :publisher
        c.type = json_data['required-type'] if pubsub == :subscriber
        c.pubsub = pubsub
        c.name = id
        c.required = json_data['required'] || false
        c
      end

      def required?
        return @required
      end
      
      def attributes
        @attributes ||= {'type' => 'nil', 'pubsub' => nil, 'name' => nil, "required" => false}
      end
      
      def attributes=(attr)
        attr.each do |name,value|
          send("#{name}=",value)
        end
      end
    end
  end
end  
    