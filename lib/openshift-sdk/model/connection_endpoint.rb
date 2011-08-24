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
  #           +-Connections
  #
  # == Properties
  # 
  # [group_name] The group in which the component is instantiated
  # [component_name] The name of the component instance
  # [connector_name] The connector name for the component
  class ConnectionEndpoint < OpenshiftModel
    validates_presence_of :group_name, :component_name, :connector_name
    ds_attr_accessor :group_name, :component_name, :connector_name
    
    def initialize(group_name, component_name, connector_name)
      @group_name, @component_name, @connector_name= group_name, component_name, connector_name
    end
  end
end
