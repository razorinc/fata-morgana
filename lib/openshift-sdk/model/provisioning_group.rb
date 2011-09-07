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
#--

require 'rubygems'
require 'json'
require 'active_model'
require 'openshift-sdk/config'
require 'openshift-sdk/model/model'
require 'openshift-sdk/model/scaling_parameters'
require 'openshift-sdk/utils/logger'

module Openshift::SDK::Model
  class ProvisioningGroup < OpenshiftModel
    ds_attr_accessor :nodes, :scaling, :arch, :memory, :disk_size
    
    def self.bucket
      "admin"
    end
    
    def initialize()
      self.nodes    = []
      self.scaling  = ScalingParameters.new
      self.arch     = "x86"
      self.memory   = 512
      self.disk_size= 10
      self.gen_uuid
    end
    
    def scaling=(hash)
      scaling_will_change!
      case hash
      when Hash
        @scaling = ScalingParameters.new
        @scaling.attributes=hash
      else
        @scaling = hash
      end
    end    
  end
end
