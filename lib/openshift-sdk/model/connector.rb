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
require 'openshift-sdk/model/model'
require 'openshift-sdk/model/connector'

module Openshift::SDK::Model
  # == Connector
  #
  # Defines a connector endpoint definition for a component. Connectors can be
  # either publishers or subscribers of information.
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
  # [type] The connector type. Eg: FILESYSTEM:DOC_ROOT
  # [pubsub] :publisher or :subscriber
  # [name] The name of this connector. This is what the hook names are based off.
  # [required] true|false. Applicable only to subscribers
  class Connector < OpenshiftModel
    validates_presence_of :type, :name, :required
    ds_attr_accessor :type, :name, :required
    
    def initialize(name=nil)
      self.name = name
      self.required = false
    end
    
    def from_descriptor_hash(hash)
      expected_keys = ["Type", "Required"]
      unknown_keys = hash.keys.clone - expected_keys
      if unknown_keys.size > 0      
        log.error "Error parsing connector. Unexpected keys: [#{unknown_keys.join(",")}]. Allowed keys are [#{expected_keys.join(",")}]"
        raise "Error parsing connector. Unexpected keys: [#{unknown_keys.join(",")}]. Allowed keys are [#{expected_keys.join(",")}]"
      end
      
      self.type = hash["Type"]
      self.required = hash["Required"].downcase == "true" if hash["Required"]
    end
    
    def to_descriptor_hash
      {
        "Type" => self.type,
        "Required" => self.required.to_s
      }
    end
  end
end  
