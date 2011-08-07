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
require 'vostok-sdk/config'
require 'vostok-sdk/model/model'
require 'vostok-sdk/model/component_instance'

module Vostok
  module SDK
    class Group < Model
      validates_presence_of :name, :components
      ds_attr_accessor :name, :components

      def self.load_descriptor(name,json_data,app_descriptor)
        g = Group.new
        g.name=name
        
        g.components = {}
        if json_data["components"]
          json_data["components"].each{|k,v|
            g.components[k] = ComponentInstance.load_descriptor(k,v)
          }
        else
          app = app_descriptor.app
          app.requires_feature.each{ |feature|
            f_inst, f_dep_cmap = ComponentInstance.from_app_dependency(feature)
            g.components.merge!(f_dep_cmap)
          }
        end
        g
      end
    end
  end
end