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

module Openshift::SDK::Model
  # == Group scaling parameters
  #
  # Defines group scaling limitations and parameters
  #
  # == Overall location within descriptor
  #
  #      |
  #      +-Profile
  #           |
  #           +-Group
  #               |
  #               +-*ScalingParameters*
  #
  # == Properties
  # 
  # [min] Minimum number nodes requires for the group
  # [max] :publisher or :subscriber
  # [default_scale_by] The name of this connector. This is what the hook names are based off.
  # [requires_dedicated]
  class ScalingParameters < OpenshiftModel
    validates_presence_of :min, :max, :default_scale_by, :requires_dedicated
    ds_attr_accessor :min, :max, :default_scale_by, :requires_dedicated
    
    def initialize(descriptor_hash={})
      @min = descriptor_hash["min"] || 1
      @max = descriptor_hash["max"] || -1
      @default_scale_by = descriptor_hash["default_scale_by"] || "+1"
      @requires_dedicated = descriptor_hash['requires_dedicated'].to_s.downcase == "true" || false
    end
    
    def generate_signature
      sigd = "false"
      sigd = Time.now.nsec.to_s if @requires_dedicated
      "#{min}-#{max}-#{sigd}"
    end
  end
end  