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
require 'openshift-sdk/model/connector'

module Openshift
  module SDK
    module Model
      class Component < OpenshiftModel
        validates_presence_of :feature
        ds_attr_accessor :feature, :publishes, :subscribes
       
        def self.load_descriptor(feature,json_data)
          publishes = json_data["connectors"]["publishes"]
          subscribes = json_data["connectors"]["subscribes"]
          
          c = Component.new
          c.feature = feature
  
          c.publishes = {}
          if publishes
            publishes.each{|k,v|
              c.publishes[k] = Connector.load_descriptor(k,v,:publisher)
            }
          end
  
          c.subscribes = {}
          if subscribes
            subscribes.each{|k,v|
              c.subscribes[k] = Connector.load_descriptor(k,v,:subscriber)
            }
          end
          c.gen_uuid
          c.save!
          
          c
        end
      end
    end
  end
end
  