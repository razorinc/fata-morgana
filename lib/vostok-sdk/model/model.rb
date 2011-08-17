# Copyright 2010 Red Hat, Inc.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'rubygems'
require 'uuid'
require 'vostok-sdk/config'
require 'vostok-sdk/utils/logger'

module Vostok
  module SDK
    module Model
      class VostokModel
        extend ActiveModel::Naming        
        include ActiveModel::Validations      
        include ActiveModel::Serializers::JSON
        #include ActiveModel::Serializers::Xml
        include ActiveModel::Dirty
        include ActiveModel::Observing
        include ActiveModel::AttributeMethods
        include ActiveModel::Observing
        include Vostok::SDK::Utils::Logger
      
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
          ds = eval("Utils::#{ds_type.capitalize}.instance")
          value = ds.find(type,id)
          return nil unless value
          ret = YAML.load(value)
          ret.loaded_from_db!
          ret
        end
        
        def loaded_from_db!
          self.changed_attributes.clear
          @errors = ActiveModel::Errors.new(self)
        end
        
        def self.find_all()
          type = self.name
          config = Vostok::SDK::Config.instance
          ds_type = config.get("datasource_type")
          require "vostok-sdk/utils/#{ds_type}_ds"
          ds = eval("Utils::#{ds_type.capitalize}.instance")
          values = ds.find_all(type)
  
          ret_vals = []
          values.each do |value|
            ret = YAML.load(value.to_s)
            ret.loaded_from_db!
            ret_vals.push(ret)
          end
          ret_vals
        end
        
        def self.find_all_guids()
          type = self.name
          config = Vostok::SDK::Config.instance
          ds_type = config.get("datasource_type")
          require "vostok-sdk/utils/#{ds_type}_ds"
          ds = eval("Utils::#{ds_type.capitalize}.instance")
          return ds.find_all_ids(type)
        end
        
        def gen_uuid
          config = Vostok::SDK::Config.instance
          uuid_state_file = config.get("uuid_state_file")
          Object::UUID.state_file=uuid_state_file
          self.guid = Object::UUID.generate(:compact)
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
        
        def to_yaml_properties
          props = []
          self.instance_variables.each do |name|
            next if name.slice(1..-1) == 'changed_attributes' or name =='attributes' or name == 'validation_context' or name == 'errors'
            props.push(name)
          end
          props.push('@guid')
          props
        end

        def attributes=(attr)
          attr.each do |name,value|
            send("#{name}=",value)
          end
        end
        
        def save!
          unless self.changed?
            log.debug "not saving #{self.class.type}. no change\n"
            return self
          end 
          unless self.valid?
            log.error "Not saving: object validation failed\n"
            return nil
          end

          type = self.class.name
          id = self.guid
          value = self.to_yaml
          log.debug "--save--"
          log.debug type
          log.debug id
          log.debug value
          log.debug "--x--"
          config = Vostok::SDK::Config.instance
          ds_type = config.get("datasource_type")
          require "vostok-sdk/utils/#{ds_type}_ds"
          ds = eval("Utils::#{ds_type.capitalize}.instance")
          yaml = ds.save(type,id,value)
          @changed_attributes.clear
          
          self
        end
        
        def delete!
          return nil unless self.changed?
          log.debug "deleting\n"
          type = self.class.name
          id = self.guid
          
          config = Vostok::SDK::Config.instance
          ds_type = config.get("datasource_type")
          require "vostok-sdk/utils/#{ds_type}_ds"
          ds = eval("Utils::#{ds_type.capitalize}.instance")
          ds.delete(type,id)
          @changed_attributes.clear
        end
        
        ds_attr_accessor :guid
        validates_presence_of :guid
      end
    end
  end
end