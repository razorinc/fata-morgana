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
require 'vostok-sdk/model/model'

module Vostok
  module SDK
    module Model
      class Connector < VostokModel
        validates_presence_of :type, :pubsub, :name, :required
        ds_attr_accessor :type, :pubsub, :name, :required
        
        def self.load_descriptor(id,json_data, pubsub)
          c = Connector.new
          c.type = json_data['type'] if pubsub == :publisher
          c.type = json_data['required-type'] if pubsub == :subscriber
          c.pubsub = pubsub
          c.name = id
          c.required = json_data['required'] || false
          c
        end
  
        def required?
          return @required
        end
      end
    end
  end
end  
    