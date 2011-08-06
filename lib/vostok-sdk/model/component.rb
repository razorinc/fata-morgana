require 'rubygems'
require 'active_model'
require 'vostok-sdk/model/model'
require 'vostok-sdk/model/connector'

module Vostok
  module SDK
    class Component < Model
      validates_presence_of :feature, :publishes, :subscribes
      ds_attr_accessor :feature, :publishes, :subscribes
      
      def attributes
        @attributes ||= {"feature" => nil, "publishes" => nil, "subscribes" => nil}
      end
      
      def attributes=(attr)
        attr.each do |name,value|
          send("#{name}=",value)
        end
      end
      

      def self.load_descriptor(feature,json_data)
        publishes = json_data["connectors"]["publishes"]
        subscribes = json_data["connectors"]["subscribes"]
        
        c = Component.new
        c.feature = feature

        c.publishes = {}
        if publishes
          publishes.each{|k,v|
            c.publishes[k] = Connector.load_descriptor(k,v,:publisher)
          }
        end

        c.subscribes = {}
        if subscribes
          subscribes.each{|k,v|
            c.subscribes[k] = Connector.load_descriptor(k,v,:subscriber)
          }
        end
        
        c
      end
    end
  end
end
  