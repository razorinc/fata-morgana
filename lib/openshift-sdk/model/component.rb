#--
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
#++

require 'rubygems'
require 'active_model'
require 'openshift-sdk/model/model'
require 'openshift-sdk/model/connector'

module Openshift::SDK::Model
  # == Component
  #
  # Defines a cartirdge component. Each component provides a feature and
  # exposes one or more publishing or subscribing connectors
  #
  # == Overall descriptor
  #   Descriptor
  #      |
  #      +-Reserviations
  #      |
  #      +-Profile
  #           |
  #           +-Provides
  #           |
  #           +-Reserviations
  #           |
  #           +-ComponentDefs
  #           |    |
  #           |    +-Connector
  #           |    |
  #           |    +-Dependencies
  #           |
  #           +-Groups
  #           |   |
  #           |   +-Reserviations
  #           |   |
  #           |   +-Scaling
  #           |   |
  #           |   +-ComponentInstances
  #           |
  #           +-Connections
  #           |   |
  #           |   +-Endpoints
  #           |
  #           +-PropertyOverrides
  #
  # == Properties
  # 
  # [feature] The feature provided by this component
  # [publishes] Hash of connectors that publish information
  # [subscribes] Hash of connectors that subscribe to information
  class Component < OpenshiftModel
    validates_presence_of :name
    ds_attr_accessor :name, :publishes, :subscribes, :dependencies, :declared_dependencies
    
    def initialize(name=nil)
      self.name = name
      self.publishes = {}
      self.subscribes = {}
      self.declared_dependencies = []  
      self.dependencies = []
    end

    def publishes=(hash)
      return unless hash.class == Hash
      publishes_will_change!
      @publishes = {}      
      hash.each do |conn_name,conn_hash|
        case conn_hash
        when Hash
          @publishes[conn_name] = Connector.new(conn_name)
          @publishes[conn_name].attributes=conn_hash
        when Connector
          @publishes[conn_name] = conn_hash
        end
      end
    end
    
    def subscribes=(hash)
      return unless hash.class == Hash
      subscribes_will_change!
      @subscribes = {}
      hash.each do |conn_name,conn_hash|
        case conn_hash
        when Hash
          @subscribes[conn_name] = Connector.new(conn_name)
          @subscribes[conn_name].attributes=conn_hash
        when Connector
          @subscribes[conn_name] = conn_hash
        end
      end
    end
    
    def from_descriptor_hash(hash,inherited_dependencies=nil)
      @publishes = {}
      if hash["Publishes"]
        publishes_will_change!
        hash["Publishes"].each do |conn_name, conn_hash|
          c = @publishes[conn_name] = Connector.new(conn_name)
          c.from_descriptor_hash(conn_hash)
        end
      end
      
      @subscribes = {}
      if hash["Subscribes"]
        subscribes_will_change!
        @subscribes = {}
        hash["Subscribes"].each do |conn_name, conn_hash|
          c = @subscribes[conn_name] = Connector.new(conn_name)
          c.from_descriptor_hash(conn_hash)
        end
      end
      self.declared_dependencies = hash["Dependencies"] if hash["Dependencies"]
      self.dependencies = self.declared_dependencies
      self.dependencies += inherited_dependencies if inherited_dependencies
    end

    def to_descriptor_hash
      p = {}
      self.publishes.each do |name,conn|
        p[name] = conn.to_descriptor_hash
      end
      
      s = {}
      self.subscribes.each do |name,conn|
        s[name] = conn.to_descriptor_hash
      end
      
      {
        "Dependencies" => self.declared_dependencies,
        "Publishes" => p,
        "Subscribes" => s
      }
    end
  end    
end

