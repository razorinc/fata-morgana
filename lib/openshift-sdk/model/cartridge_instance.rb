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
require 'json'
require 'openshift-sdk/config'
require 'openshift-sdk/model/model'
require 'openshift-sdk/model/rpm'
require 'openshift-sdk/model/descriptor'

module Openshift::SDK::Model
  class CartridgeInstance < OpenshiftModel
    ds_attr_accessor :profile, :cartridge, :component_instance, :cartridge_name
    
    def initialize(comp_inst, profile_name, cartridge)
      self.component_instance = comp_inst
      self.profile = profile_name
      self.cartridge = cartridge
      self.cartridge_name = self.cartridge.name
    end

    def get_all_component_instances
      # this function assumes that the cartridge has been elaborated (references resolved)
      p_obj = self.cartridge.descriptor.profiles[self.profile]
      if not p_obj
        return []
      end
      p_obj.get_all_component_instances
    end

  end
end
