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
require 'json'
require 'active_model'
require 'openshift-sdk/config'
require 'openshift-sdk/utils/logger'
require 'openshift-sdk/utils/shell_exec'
require "openshift-sdk/utils/sqlite_ds"

ActiveSupport::JSON.backend = "JSONGem" 
module Openshift
  module SDK
    module Model
      class OpenshiftModel
        extend ActiveModel::Naming        
        include ActiveModel::Validations      
        include ActiveModel::Serializers::JSON
        self.include_root_in_json = false
        include ActiveModel::Serializers::Xml
        include ActiveModel::Dirty
        include ActiveModel::Observing
        include ActiveModel::AttributeMethods
        include ActiveModel::Observing
        include ActiveModel::Conversion
        include Openshift::SDK::Utils::Logger
        
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
        
        def self.bucket
          #app bucket is based on user group id
          o,e,rc = Openshift::SDK::Utils::ShellExec::shellCmd('id -ng')
          o.strip!
        end
        
        def self.find(id,bucket=nil)
          bucket ||= self.bucket
          Openshift::SDK.log.debug("find #{self.name} id:#{id} bucket:#{bucket}")
          binding.pry unless bucket
          
          type = self.name
          config = Openshift::SDK::Config.instance
          ds_type = config.get("datasource_type")
          ds = eval("Utils::#{ds_type.capitalize}.instance")
          value = ds.find(type,id,bucket)
          return nil unless value
          ret = YAML.load(value)
          ret.loaded_from_db!
          ret
        end
        
        def loaded_from_db!
          self.changed_attributes.clear
          @errors = ActiveModel::Errors.new(self)
        end
        
        def self.find_all(bucket=nil)
          bucket ||= self.bucket
          Openshift::SDK.log.debug("find-all #{self.name} bucket:#{bucket}")

          type = self.name
          config = Openshift::SDK::Config.instance
          ds_type = config.get("datasource_type")
          ds = eval("Utils::#{ds_type.capitalize}.instance")
          values = ds.find_all(type,bucket)
  
          ret_vals = []
          values.each do |value|
            ret = YAML.load(value.to_s)
            ret.loaded_from_db!
            ret_vals.push(ret)
          end
          ret_vals
        end
        
        def self.find_all_guids(bucket=nil)
          bucket ||= self.bucket
          Openshift::SDK.log.debug("find-all-guid #{self.name} bucket:#{bucket}")
          type = self.name
          config = Openshift::SDK::Config.instance
          ds_type = config.get("datasource_type")
          ds = eval("Utils::#{ds_type.capitalize}.instance")
          return ds.find_all_ids(type,bucket)
        end
        
        def gen_uuid
          fp = File.new("/proc/sys/kernel/random/uuid", "r")
          self.guid = fp.gets.strip
          fp.close
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
            next if name == '@changed_attributes' or name == '@attributes' or name == '@validation_context' or name == '@errors'
            props.push(name)
          end
          props.push('@guid')
          props
        end

        def attributes=(attr)
          return if attr.nil?
          attr.each do |name,value|
            send("#{name}=",value)
          end
        end
        
        def save!(bucket=nil)
          bucket ||= self.class.bucket
          
          unless self.changed?
            log.debug "not saving #{self.class.name}. no change\n"
            return self
          end 
          unless self.valid?
            log.error "Not saving: object of type #{self.class.name} validation failed #{self.errors.to_s}\n"
            return nil
          end

          type = self.class.name
          id = self.guid
          value = self.to_yaml
          log.debug "saving type: #{type}, id: #{id}, bucket: #{bucket}"
          config = Openshift::SDK::Config.instance
          ds_type = config.get("datasource_type")
          ds = eval("Utils::#{ds_type.capitalize}.instance")
          yaml = ds.save(type,id,value,bucket)
          @changed_attributes.clear
          
          self
        end
        
        def delete!
          bucket ||= self.class.bucket
                    
          return nil unless self.changed?
          log.debug "deleting\n"
          type = self.class.name
          id = self.guid
          
          config = Openshift::SDK::Config.instance
          ds_type = config.get("datasource_type")
          ds = eval("Utils::#{ds_type.capitalize}.instance")
          ds.delete(type,id,bucket)
          @changed_attributes.clear
        end

        def persisted?
          false
        end
        
        ds_attr_accessor :guid
        ds_attr_reader :bucket
        validates_presence_of :guid
      end
    end
  end
end
