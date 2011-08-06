require 'rubygems'
require 'vostok-sdk/config'

module Vostok
  module SDK
    class Model
      include ActiveModel::Validations      
      include ActiveModel::Serializers::JSON
      include ActiveModel::Serializers::Xml
      include ActiveModel::Dirty
      include ActiveModel::Observing
      include ActiveModel::AttributeMethods
    
      def self.ds_attr_reader(*accessors)
        define_attribute_methods accessors
        
        accessors.each do |m|
          define_method(m) do  
            instance_variable_get("@#{m}")
          end
        end
      end
      
      def self.ds_attr_writer(*accessors)
        define_attribute_methods accessors
        
        accessors.each do |m|
          class_eval <<-EOF
            def #{m}=(val)
              #{m}_will_change! unless @#{m} == val
              instance_variable_set("@#{m}",val)
            end
          EOF
        end
      end
      
      def self.ds_attr_accessor(*accessors)
        ds_attr_reader(*accessors)
        ds_attr_writer(*accessors)
      end
      
      def self.find(id)
        type = self.name
        config = Vostok::SDK::Config.instance
        ds_type = config.get("datasource_type")
        require "vostok-sdk/utils/#{ds_type}_ds"
        ds = eval("#{ds_type.capitalize}.instance")
        value = ds.find(type,id)

        ret = new.from_json(value)
        ret.changed_attributes.clear
        ret
      end
      
      def attributes
        return @attributes if @attributes
        @attributes = {}
        self.instance_variables.each do |name|
          name = name.slice(1..-1)
          next if name == 'changed_attributes' or name =='attributes' or name == 'validation_context' or name == 'errors'
          @attributes[name] = nil
        end
        @attributes["guid"] = nil
        @attributes
      end
      
      def attributes=(attr)
        attr.each do |name,value|
          send("#{name}=",value)
        end
      end
      
      def save()
        return nil unless self.changed?
        unless self.valid?
          print "Not saving: object validation failed\n"
          return nil
        end
        type = self.class.name
        id = self.guid
        value = self.to_json
        
        config = Vostok::SDK::Config.instance
        ds_type = config.get("datasource_type")
        require "vostok-sdk/utils/#{ds_type}_ds"
        ds = eval("#{ds_type.capitalize}.instance")
        json = ds.save(type,id,value)
        from_json(json)
        @changed_attributes.clear
        
        self
      end
      
      ds_attr_accessor :guid
      validates_presence_of :guid
    end
  end
end