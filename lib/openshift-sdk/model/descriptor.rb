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
  # [profiles] Hash list of all profiles defined in the descriptor
  class Descriptor < OpenshiftModel
    validates_presence_of :profiles
    ds_attr_accessor :profiles, :reservations, :parent_cartridge

    def initialize(parent_cartridge = nil)
      self.profiles = {}
      self.reservations = []
      self.parent_cartridge = parent_cartridge
    end
    
    def [](profile_name)
      @profiles[profile_name]
    end
    
    def []=(profile_name,profile)
      raise InvalidDescriptorException("Expected object of type Profile. (Param type:#{profile.class.name})") if profile.class != Profile
      profiles_will_change! if @profiles[profile_name] != profile
      @profiles[profile_name] = profile
    end
    
    def resolve_references(profile_name=nil)
      self.profiles.each do |pname, profile|
        if profile_name.nil? or profile_name == "" or profile_name == pname 
          profile.resolve_references
          break
        end
      end
    end
    
    def from_descriptor_hash(hash,inherited_dependencies=nil)
      expected_keys = ["Reservations", "Profiles",    #from descriptor level
                       "Provides", "Property Overrides", "Components", "Groups", "Connections", "Start-Order", #from profile level
                       "Dependencies", "Publishes", "Subscribes",  #from component level
                       "Scaling"]  #from groups
      unknown_keys = hash.keys.clone - expected_keys
      if unknown_keys.size > 0
        log.error "Error parsing descriptor. Unexpected keys: [#{unknown_keys.join(",")}]. Allowed keys are [#{expected_keys.join(",")}]"
        raise "Error parsing descriptor. Unexpected keys: [#{unknown_keys.join(",")}]. Allowed keys are [#{expected_keys.join(",")}]"
      end
      
      if hash["Reservations"]
        self.reservations = hash["Reservations"]
      end
      if hash["Profiles"]
        hash["Profiles"].each do |profile_name,profile_hash|
          p = self[profile_name] = Profile.new(profile_name)
          p.user_defined = true
          p.parent_descriptor = self
          p.from_descriptor_hash(profile_hash,inherited_dependencies)
        end
      else
        p = self["default"] = Profile.new("default")
        p.parent_descriptor = self
        p.from_descriptor_hash(hash,inherited_dependencies)
      end
    end
    
    def to_descriptor_hash
      h = {}

      h["Reservations"] = self.reservations if self.reservations.length > 0

      p = {}
      self.profiles.each do |name, profile|
        if not profile.user_defined
          h.merge! profile.to_descriptor_hash
        else
          p[name] = profile.to_descriptor_hash
        end
      end

      if p.length > 0
        h["Profiles"] = p
      end
      h
    end
  end
end

