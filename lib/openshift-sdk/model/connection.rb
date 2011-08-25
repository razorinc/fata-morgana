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

module Openshift::SDK::Model
  # == Connection
  # 
  # Defines a connection between two component connectors
  #
  # == Overall location within descriptor
  #
  #      |
  #      +-Profile
  #           |
  #           +-Group
  #           |   |
  #           |   +-Scaling
  #           |   |
  #           |   +-Component
  #           |         |
  #           |         +-Connector
  #           |
  #           +-*Connection*
  #               |
  #               +-ConnectionEndpoint
  #
  # == Properties
  # 
  # [name] Connection name
  # [pub] The publishing connection endpoint
  # [sub] The subscribing connection endpoint
  class Connection < OpenshiftModel
    validates_presence_of :name, :pub, :sub, :type
    ds_attr_accessor :name, :pub, :sub, :type

    def initialize(name=nil,pub=nil,sub=nil,type=nil)
      @name, @pub, @sub, @type = name, pub, sub, type
    end

    def pub=(val)
      if val.class == Hash
        @pub=ConnectionEndpoint.new
        @pub.attributes=val
      else
        @pub = val        
      end
    end

    def sub=(val)
      if val.class == Hash
        @sub=ConnectionEndpoint.new
        @sub.attributes=val
      else
        @sub = val        
      end
    end
  end
end
