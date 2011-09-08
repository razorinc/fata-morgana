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
  # == Overall descriptor
  #
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
  # [name] Connection name
  # [pub] The publishing connection endpoint
  # [sub] The subscribing connection endpoint
  class Connection < OpenshiftModel
    ds_attr_accessor :name, :components, :endpoints, :profile

    def initialize(name)
      self.components = []
      self.name = name
      self.endpoints = []
      self.profile = nil
    end

    def from_descriptor_hash(hash)
      self.components = hash["Components"]
    end
    
    def to_descriptor_hash
      {
        "Components" => self.components
      }
    end

    def resolve_references
      if self.components.class != Array or self.components.length != 2
        raise "Malformed components in connection #{self.name}"
      end
      if self.profile.nil?
        raise "No profile given to resolve connections against"
      end
      comp1, comp2 = self.components
      res_comp1 = nil
      res_comp2 = nil
      # search for comp1 and comp2 in profile
      # assume that the profile has its components resolved
      profile.groups.each { |group_name, group|
        group.resolved_components_hash.each { |comp_inst_name, comp_inst|
          if comp_inst_name==comp1 or comp_inst.component.name == comp1
            res_comp1 = comp_inst
          end
          if comp_inst_name==comp2 or comp_inst.component.name == comp2
            res_comp2 = comp_inst
          end
          if res_comp1 and res_comp2
            return endpoints_from_components(res_comp1, res_comp2)
          end
        }
        if res_comp1 and res_comp2
          return endpoints_from_components(res_comp1, res_comp2)
        end
      }
      # if flow reaches here, it means comp1/2 did not get resolved
      # by looking at component/instance names, we need to look into
      # dependencies of each component
      profile.groups.each { |group_name, group|
        group.resolved_components_hash.each { |comp_inst_name, comp_inst|
          comp_inst.cartridge_instances.each { |cart_profile_name, cart_inst|
            cart_name, profile_name = cart_profile_name.split(":")
            if cart_name == comp1 or cart_profile_name == comp1
              res_comp1 = cart_inst
            end
            if cart_name == comp2 or cart_profile_name == comp2
              res_comp2 = cart_inst
            end
            if res_comp1 and res_comp2
              return endpoints_from_cart_instances(res_comp1, res_comp2)
            end
          }
          if res_comp1 and res_comp2
            return endpoints_from_cart_instances(res_comp1, res_comp2)
          end
        }
        if res_comp1 and res_comp2
          return endpoints_from_cart_instances(res_comp1, res_comp2)
        end
      }
      # if the flow reaches here, endpoints were not resolved
      if res_comp1.nil?
        raise "Could not resolve connection component #{comp1} in profile #{self.profile.name}"
      end
      if res_comp2.nil?
        raise "Could not resolve connection component #{comp2} in profile #{self.profile.name}"
      end
    end

    def endpoints_from_components(comp1, comp2)
      # get all published from comp1 and match to subscribed of comp2
      # then vice versa
      pub_hash = {}
      comp1.component.publishes.each { |conn_name, connector|
        pub_hash[connector.type] = connector
      }
      comp2.component.subscribes.each { |conn_name, connector|
        if pub_hash[connector.type] 
          self.endpoints.push(ConnectionEndpoint.new(comp1, pub_hash[connector.type], comp2, connector))
        end
      }

      pub_hash = {}
      comp2.component.publishes.each { |conn_name, connector|
        pub_hash[connector.type] = connector
      }
      comp1.component.subscribes.each { |conn_name, connector|
        if pub_hash[connector.type] 
          self.endpoints.push(ConnectionEndpoint.new(comp2, pub_hash[connector.type], comp1, connector))
        end
      }
    end

    def endpoints_from_cart_instances(cart1, cart2)
      comp1_list = []
      comp2_list = []
      cart1.cartridge.descriptor.profiles.each { |profile_name, profile|
        comp1_list += profile.get_all_component_instances
      }
      cart2.cartridge.descriptor.profiles.each { |profile_name, profile|
        comp2_list = profile.get_all_component_instances
      }

      # get cart1's publishers and cart2's subscribers and match up
      pub_hash = {}
      comp1_list.each { |comp_inst|
        comp_inst.component.publishes.each { |conn_name, connector|
          pub_hash[connector.type] = connector, comp_inst
        }
      }

      comp2_list.each { |comp_inst|
        comp_inst.component.subscribes.each { |conn_name, connector|
          if pub_hash[connector.type]
            pub_connector, pub_inst = pub_hash[connector.type]
            self.endpoints.push(ConnectionEndpoint.new(pub_inst, pub_connector, comp_inst, connector))
          end
        }
      }

      # now repeat the reverse way.. get cart2 publishers and cart1's subscribers
      pub_hash = {}
      comp2_list.each { |comp_inst|
        comp_inst.component.publishes.each { |conn_name, connector|
          pub_hash[connector.type] = connector, comp_inst
        }
      }

      comp1_list.each { |comp_inst|
        comp_inst.component.subscribes.each { |conn_name, connector|
          if pub_hash[connector.type]
            pub_connector, pub_inst = pub_hash[connector.type]
            self.endpoints.push(ConnectionEndpoint.new(pub_inst, pub_connector, comp_inst, connector))
          end
        }
      }
    end

  end
end

