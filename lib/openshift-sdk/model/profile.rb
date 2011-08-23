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
require 'json'
require 'active_model'
require 'openshift-sdk/model/model'
require 'openshift-sdk/model/component'

module Openshift::SDK::Model
  # == Profile
  #
  # Defines a cartridge or application profile. 
  #
  # == Overall location within descriptor
  #
  #      |
  #      +-*Profile*
  #           |
  #           +-Group
  #               |
  #               +-Scaling
  #               |
  #               +-Component
  #                     |
  #                     +-Connector
  #
  # == Properties
  # 
  # [name] The name of the group
  # [groups] A hash map with all groups for this profile
  class Profile < OpenshiftModel
    validates_presence_of :name, :groups
    ds_attr_accessor :name, :groups
    
    def initialize(name=nil,descriptor_data={},cartridge=nil)
      self.name = name
      self.groups = {}
      if descriptor_data["groups"]
        descriptor_data["groups"].each do |name, grp_data|
          @groups[name] = Group.new(name,grp_data,cartridge)
        end
      else
        @groups["default"] = Group.new("default",descriptor_data,cartridge)
      end
    end
    
    def groups=(vals)
      @groups = {}
      return if vals.class != Hash
      vals.keys.each do |name|
        next if name.nil?
        if vals[name].class == Hash
          @groups[name] = Component.new
          @groups[name].attributes=vals[name]
        else
          @groups[name] = vals[name]
        end
      end
    end
  end
end