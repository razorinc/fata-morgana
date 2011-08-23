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
require 'openshift-sdk/model/cartridge'
require 'openshift-sdk/model/profile'

module Openshift::SDK::Model
  # == Cartridge descriptor
  #
  # Descriptor object that defines all possible profiles/groups/components 
  # available in the cartridge
  #
  # == Overall descriptor
  #   Descriptor
  #      |
  #      +-Profile
  #           |
  #           +-Group
  #               |
  #               +-Scaling
  #               |
  #               +-Component
  #                     |
  #                     +-Connector
  #
  # == Properties
  # 
  # [profiles] Hash list of all profiles defined in the descriptor
  class Descriptor < OpenshiftModel
    validates_presence_of :profiles
    ds_attr_accessor :profiles
    
    def initialize(cartridge=nil)
      @profiles = {}
      return if cartridge.nil?
      f = File.open("#{cartridge.package_path}/openshift/descriptor.json")
      json_data = JSON.parse(f.read)
      if json_data["profiles"]
        json_data["profiles"].each do |name, prof_data|
          @profiles[name] = Profile.new(name,prof_data,cartridge)
        end
      else
        @profiles["default"] = Profile.new("default",json_data,cartridge)
      end
    end
  end
end
