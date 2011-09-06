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
require 'active_model'
require 'openshift-sdk/model/model'
require 'openshift-sdk/model/descriptor'
require 'openshift-sdk/model/cartridge'
require 'openshift-sdk/model/component_instance'
require 'openshift-sdk/model/feature_cartridge_cache'

module Openshift::SDK::Model
  class ComponentInstance < OpenshiftModel
    validates_presence_of :component
    ds_attr_accessor :name, :component
    
    def initialize(name, component_def)
      self.name = name
      self.component = component_def
      self.gen_uuid
    end
    
    #for XML, JSON serialization
    def attributes
      {"name"=> @name, "component" => self.component}
    end
    
  end
end
