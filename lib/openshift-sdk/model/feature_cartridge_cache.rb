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
require 'singleton'
require 'openshift-sdk/model/cartridge'

module Openshift::SDK::Model
  class FeatureCartridgeCache < OpenshiftModel
    def self.instance
      @@instance ||= FeatureCartridgeCache.find("feature-cartridge-map")
      @@instance ||= FeatureCartridgeCache.new
    end

    validates_presence_of :map
    ds_attr_accessor :map
    
    def initialize
      @map = {}
      @guid = "feature-cartridge-map"
    end
  
    def what_provides(feature)
      return @map[feature].map{ |cguid| Cartridge.find(cguid) } if @map[feature]
      map_will_change!
      carts = Cartridge.what_provides(feature)
      carts.each do |cart|
        cart.save!
      end
      
      @map[feature] = carts.map{ |cart| cart.guid }
      save!
      map[feature].map{ |cguid| Cartridge.find(cguid) }
    end
  end
end
