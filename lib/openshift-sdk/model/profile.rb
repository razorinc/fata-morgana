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
require 'openshift-sdk/model/group'
require 'openshift-sdk/model/component_instance'
require 'openshift-sdk/model/connection'
require 'openshift-sdk/model/connection_endpoint'

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
          components = {}
          if descriptor_data["components"]
            #all components have already been defined in the provided descriptor
            descriptor_data["components"].each{|comp_name,comp_hash|
              components[comp_name] = ComponentInstance.new(comp_name,comp_hash)
            } 
          else
            #no components have been defined in descriptor so have to create 
            #them based on application dependencies
            app_dependencies = cartridge.requires_feature
            app_dependencies.each do |feature|
              components.merge! ComponentInstance.component_instance_for_feature(feature)
            end
          end
          self.connections = load_connections(components,descriptor_data)
        end
      else
        if cartridge.class == Cartridge
          @groups["default"] = Group.new("default",descriptor_data,cartridge)
          components = {}
          if descriptor_data["components"]
            #all components have already been defined in the provided descriptor
            descriptor_data["components"].each{|comp_name,comp_hash|
              components[comp_name] = ComponentInstance.new(comp_name,comp_hash)
            } 
          else
            #no components have been defined in descriptor so have to create 
            #them based on application dependencies
            app_dependencies = cartridge.requires_feature
            app_dependencies.each do |feature|
              components.merge! ComponentInstance.component_instance_for_feature(feature)
            end
          end
          self.connections = load_connections(components,descriptor_data)
        end
        
        if cartridge.class == Application
          components = {}
          if descriptor_data["components"]
            #all components have already been defined in the provided descriptor
            descriptor_data["components"].each{|comp_name,comp_hash|
              components[comp_name] = ComponentInstance.new(comp_name,comp_hash)
            } 
          else
            #no components have been defined in descriptor so have to create 
            #them based on application dependencies
            app_dependencies = cartridge.requires_feature
            app_dependencies.each do |feature|
              components.merge! ComponentInstance.component_instance_for_feature(feature)
            end
          end
          
          #all components instances are known, now decide connections
          log.debug components.to_yaml
          
          #components may not be in groups yet 
          log.debug "load connections ...\n"
          connections = load_connections(components,descriptor_data)

          #look for components that must be co-located
          colocated_components = {}
          colocated_components.default = []
          connections.each do |conn_name, conn|
            if conn.type.match(/^FILESYSTEM/)
              colocated_components[conn.pub.component_name].push(conn.sub.component_name)
              colocated_components[conn.sub.component_name].push(conn.pub.component_name)
            end
          end
          
          #start forming groups based on group signature and colocation constraints
          proc_components = components.values.clone
          groups = {}
          while proc_components.size > 0
            cinst = proc_components.pop
            next if cinst.nil?
            comp_group = cinst.cartridge.descriptor.profiles[cinst.profile_name].groups[cinst.component_group_name]            
            
            #match groups based on colocated instances
            colos = colocated_components[cinst.guid]
            colos.each do |colo_cinst_name|
              colo_cinst = components[colo_cinst_name]
              if colo_cinst.group_name
                cinst.group_name = colo_cinst.group_name                
                groups[cinst.group_name].components[cinst.guid] = cinst
                #TODO: adjust group scaling or error out if necessary
              end
            end
            
            #match groups based on group signature
            unless cinst.group_name
              group_sig = comp_group.signature
              groups.each do |gname, ginst|
                if ginst.signature == group_sig
                  ginst.components[cinst.guid] = cinst
                  cinst.group_name = ginst.guid
                end
              end
            end
            
            #if no group signature match or colocated requirement then make 
            #a new group
            unless cinst.group_name
              g = Group.new
              g.scaling = comp_group.scaling.clone
              g.gen_uuid
              groups[g.guid] = g
              g.components[cinst.guid] = cinst
              cinst.group_name = g.guid
            end
          end 
          
          #update connections based on new groups
          connections.each do |cname, conn|
            conn.pub.group_name = components[conn.pub.component_name].group_name
            conn.sub.group_name = components[conn.sub.component_name].group_name
          end
          
          self.connections = connections
          self.groups = groups
        end
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

    private

    def load_connections(components, descriptor_data={})
      connections = {}
      components.each do |cname, cinst|
        log.debug "Connections for #{cname}\n"
        cinst.dependency_instances.each do |dep_cinst_name|
          log.debug "\tDep name #{dep_cinst_name}\n"
          dep_cinst = components[dep_cinst_name]
          connections.merge! create_connections(dep_cinst, cinst)
        end
      end

      if descriptor_data["connections"]
        descriptor_data["connections"].each do |name, conn_info|
          cinst1 = find_component(components, conn_info[0])
          cinst2 = find_component(components, conn_info[1])
          
          log.error("Unable to find component instance named #{conn_info[0]} for connection #{name}") unless cinst1
          log.error("Unable to find component instance named #{conn_info[1]} for connection #{name}") unless cinst2
          next if cinst1.nil? or cinst2.nil?

          connections.merge! create_connections(cinst1,cinst2)
        end
      end
      
      connections
    end
    
    def find_component(components, name)
      return components[name] if components[name]
        
      #if not a name, search by feature
      components.each do |cname, cinst|
        return cinst if cinst.component.feature == name
      end
    end

    def create_connections(cinst1,cinst2)
      ret_connections = {}
      type_publisher = {}
      [cinst1,cinst2].each do |cinst|
        cinst.component.publishes.each do |cname,cinfo|
          type = cinfo.type
          type_publisher[type] = [] unless type_publisher[type]
          type_publisher[type].push({"group"=> cinst.component_group_name, "comp"=> cinst, "conn_name"=> cname})
        end
      end

      [cinst1,cinst2].each do |cinst|
        cinst.component.subscribes.each{ |cname,cinfo|
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
          sub = ConnectionEndpoint.new(cinst.component_group_name, cinst.guid, cname)

          publishers.each do |data|
            pub_group_name = data['group']
            pub_group = groups[pub_group_name]
            pub_comp_name = data['comp'].guid
            pub_conn_name = data['conn_name']
            pub_comp = data['comp']
            
            pub = ConnectionEndpoint.new(pub_group_name, pub_comp_name, pub_conn_name)

            conn_name = "conn#{Time.now.usec}"
            conn = Connection.new(conn_name, pub, sub, req_type)
            conn.gen_uuid
            ret_connections[conn.guid] = conn
          end
        }
      end
      ret_connections
    end

  end
end
