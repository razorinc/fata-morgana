require 'rubygems'
require 'active_model'
require 'vostok-sdk/model/model'

module Vostok
  module SDK
    class Connection < Model
      validates_presence_of :name, :pub, :sub
      ds_attr_accessor :name, :pub, :sub, :attributes

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