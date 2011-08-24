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
require 'json'
require 'active_model'
require 'openshift-sdk/model/model'
require 'openshift-sdk/model/component'

module Openshift::SDK::Model
  # == Profile
  #
  # Defines a cartridge or application profile. 
  #
  # == Overall location within descriptor
  #
  #      |
  #      +-*Profile*
  #           |
  #           +-Group
  #           |   |
  #           |   +-Scaling
  #           |   |
  #           |   +-Component
  #           |         |
  #           |         +-Connector
  #           |
  #           +-Connection
  #               |
  #               +-ConnectionEndpoint
  #
  # == Properties
  # 
  # [name] The name of the group
  # [groups] A hash map with all groups for this profile
  class Profile < OpenshiftModel
    validates_presence_of :name, :groups
    ds_attr_accessor :name, :groups, :connections
    
    def initialize(name=nil,descriptor_data={},cartridge=nil)
      self.name = name
      self.groups = {}
      self.connections = {}
      if descriptor_data["groups"]
        descriptor_data["groups"].each do |name, grp_data|
          @groups[name] = Group.new(name,grp_data,cartridge)
        end
      else
        @groups["default"] = Group.new("default",descriptor_data,cartridge)
      end

      if cartridge.class == Application
        load_connections(descriptor_data)
      end
    end
    
    def groups=(vals)
      @groups = {}
      return if vals.class != Hash
      vals.keys.each do |name|
        next if name.nil?
        if vals[name].class == Hash
          @groups[name] = Group.new
          @groups[name].attributes=vals[name]
        else
          @groups[name] = vals[name]
        end
      end
    end

    def connections=(vals)
      @connections = {}
      return if vals.class != Hash
      vals.keys.each do |name|
        next if name.nil?
        if vals[name].class == Hash
          @connections[name] = Connection.new
          @connections[name].attributes=vals[name]
        else
          @connections[name] = vals[name]
        end
      end
    end

    def load_connections(descriptor_data={})
      groups.each do |gname, group|
        group.components.each do |cname, cinst|
          if cinst.dependency_instances.keys.size > 0
            cinst.dependency_instances.each do |dep_feature,dep_cinst_data|
              dep_cinst_data["cinst_names"].each do |cinst_name|
                dep_cinst = groups[dep_cinst_data["group_name"]].components[cinst_name]
                cinst1 = {"group_name" => dep_cinst_data["group_name"], "cinst" => dep_cinst}
                cinst2 = {"group_name" => group.name, "cinst" => cinst}
                establish_connection(cinst1, cinst2)
              end
            end
          end
        end
      end

      if descriptor_data["connections"]
        descriptor_data["connections"].each do |name, conn_info|
          cinst1 = find_cinst_by_name(conn_info[0])
          cinst2 = find_cinst_by_name(conn_info[1])

          log.error("Unable to find component instance named #{conn_info[0]} for connection #{name}") unless cinst1
          log.error("Unable to find component instance named #{conn_info[1]} for connection #{name}") unless cinst2
          next if cinst1.nil? or cinst2.nil?

          establish_connection(cinst1,cinst2)
        end
      end
    end

    def establish_connection(cinst1,cinst2)
      type_publisher = {}
      [cinst1,cinst2].each do |cinst_info|
        cinst_info["cinst"].component.publishes.each do |cname,cinfo|
          type = cinfo.type
          type_publisher[type] = [] unless type_publisher[type]
          type_publisher[type].push({"group"=> cinst_info["group_name"], "comp_name"=> (cinst_info["cinst"].name), "conn_name"=> cname})
        end
      end

      [cinst1,cinst2].each do |cinst_info|
        cinst_info["cinst"].component.subscribes.each{ |cname,cinfo|
          req_type = cinfo.type
          publishers = type_publisher[req_type]
          unless publishers
            if cinfo.required
              print "publisher of #{req_type} not found\n" if publishers.nil?
              exit
            else
              next
            end
          end
          sub = ConnectionEndpoint.new(cinst_info["group_name"], cinst_info["cinst"].name, cname)

          publishers.each do |data|
            pub_group_name = data['group']
            pub_group = groups[pub_group_name]
            pub_comp_name = data['comp_name']
            pub_conn_name = data['conn_name']
            pub_comp = pub_group.components[pub_comp_name]
            pub = ConnectionEndpoint.new(pub_group_name, pub_comp_name, pub_conn_name)

            conn_name = "conn#{(self.connections.size+1)}"
            self.connections[conn_name] = Connection.new(conn_name, pub, sub)
          end

        }
      end
    end

    def find_cinst_by_name(cname)
      groups.each do |gname, group|
        cinst = group.components[cname]
        return {"group_name" => gname, "cinst" => cinst} if cinst
      end
      nil
    end
  end
end
