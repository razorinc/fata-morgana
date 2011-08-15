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
require 'vostok-sdk/config'
require 'vostok-sdk/model/model'
require 'vostok-sdk/model/cartridge'
require 'vostok-sdk/model/profile'

module Vostok
  module SDK
    module Model
      class Descriptor < VostokModel
        validates_presence_of :profiles
        ds_attr_accessor :profiles
  
        def self.load_descriptor(cartridge)
          d = Descriptor.new
          f = File.open("#{cartridge.package_path}/vostok/descriptor.json")
          
          json_data = JSON.parse(f.read)
          d.profiles = {}
          if json_data.has_key?("profiles")
            json_data["profiles"].each{|k,v|
              d.profiles[k] = Profile.load_descriptor(k,v,cartridge)
            }
          else
            d.profiles["default"] = Profile.load_descriptor("default",json_data,cartridge)
          end
          
          d
        end
      end
    end
  end
end
