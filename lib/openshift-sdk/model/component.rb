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
  # == Overall location within descriptor
  #
  #      |
  #      +-Profile
  #           |
  #           +-Group
  #               |
  #               +-Scaling
  #               |
  #               +-*Component*
  #                     |
  #                     +-Connector
  #
  # == Properties
  # 
  # [feature] The feature provided by this component
  # [publishes] Hash of connectors that publish information
  # [subscribes] Hash of connectors that subscribe to information
  class Component < OpenshiftModel
    validates_presence_of :feature
    ds_attr_accessor :feature, :publishes, :subscribes
   
    def initialize(feature=nil,desriptor_hash={})
      @feature = feature
      @publishes = {}
      @subscribes = {}
      if desriptor_hash["connectors"]
        publishes = desriptor_hash["connectors"]["publishes"]
        subscribes = desriptor_hash["connectors"]["subscribes"]
        @publishes = {}
        if publishes
          publishes.each{|name,conn_hash|
            @publishes[name] = Connector.new(name,:publisher,conn_hash)
          }
        end

        @subscribes = {}
        if subscribes
          subscribes.each{|name,conn_hash|
            @subscribes[name] = Connector.new(name,:subscriber,conn_hash)
          }
        end
      end
    end
    
    def publishes=(vals)
      @publishes = {}
      return if vals.class != Hash
      vals.keys.each do |name|
        next if name.nil?
        if vals[name].class == Hash
          @publishes[name] = Connector.new
          @publishes[name].attributes=vals[name]
        else
          @publishes[name] = vals[name]
        end
      end
    end
   
    def subscribes=(vals)
      @subscribes = {}
      return if vals.class != Hash
      vals.keys.each do |name|
        next if name.nil?
        if vals[name].class == Hash
          @subscribes[name] = Connector.new
          @subscribes[name].attributes=vals[name]
        else
          @subscribes[name] = vals[name]
        end
      end
    end
  end
end
