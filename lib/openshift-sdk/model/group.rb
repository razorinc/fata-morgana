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
require 'openshift-sdk/model/model'
require 'openshift-sdk/model/group_signature'
require 'openshift-sdk/model/component_instance'
require 'openshift-sdk/utils/logger'

module Openshift
  module SDK
    module Model
      class Group < OpenshiftModel
        validates_presence_of :name, :components
        ds_attr_accessor :name, :components, :nodes
        
        def initialize
          self.nodes = []
        end
        
        def self.load_descriptor(name,json_data,app_descriptor,app)
          g = Group.new
          g.name=name
          
          g.components = {}
          if json_data["components"]
            json_data["components"].each{|k,v|
              g.components[k] = ComponentInstance.load_descriptor(k,v)
            }
          else
            app.requires_feature.each{ |feature|
              f_inst, f_dep_cmap = ComponentInstance.from_app_dependency(feature)
              g.components.merge!(f_dep_cmap)
            }
          end
          
          #generate group sigature to see if we can share group between applications
          sig = Model::GroupSignature.gen_signature(g)
          gsig = Model::GroupSignature.find(sig)
          unless gsig
            g.gen_uuid
            g.save!
            gsig = Model::GroupSignature.new(sig,g)
            gsig.save!
          else
            g = Group.find(gsig.group_guid)
          end
          
          g
        end
      end
    end
  end
end