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
require 'vostok-sdk/config'
require 'vostok-sdk/model/cartridge'
require 'vostok-sdk/model/group'
require 'vostok-sdk/model/connection'
require 'vostok-sdk/model/connection_endpoint'
require 'vostok-sdk/model/model'

module Vostok
  module SDK
    class AppDescriptor < Model
      ds_attr_accessor :groups, :connections, :app
      validates_presence_of :groups, :connections, :app
     
      def self.load_descriptor(app)
        d = AppDescriptor.new
        d.app = app
        f = File.open("#{app.package_path}/vostok/descriptor.json")
        json_data = JSON.parse(f.read)

        #load groups
        d.groups = {}
        if json_data.has_key?("groups")
          json_data["groups"].each{ |k,v|
            d.groups[k] = Group.load_descriptor(k,v)
          }
        else
          d.groups["default"] = Group.load_descriptor("default",json_data,d)
        end
        
        #load connections
        d.connections = {}
        
        type_publisher = {}
        d.groups.each{ |gn,g|
          g.components.each{ |k,v|
            v.component.publishes.each{ |cname,cinfo|
              type = cinfo.type
              type_publisher[type] = [] unless type_publisher[type]
              type_publisher[type].push({"group"=> g.name, "comp_name"=> k, "conn_name"=> cname})
            }
          }
        }

        other_connections = {}
        other_connections = json_data['connections'] if json_data['connections']
        
        conn_id = 0
        d.groups.each{ |gn,g|
          g.components.each{ |k,v|
            v.component.subscribes.each{ |cname,cinfo|
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
              
              publishers.each{ |data|
                pub_group = data['group']
                pub_comp_name = data['comp_name']
                pub_conn_name = data['conn_name']
                pub_comp = d.groups[pub_group].components[pub_comp_name]
                sub_comp = v

                is_direct_dependency = sub_comp.dependency_instances.values.flatten.include?(pub_comp_name) or pub_comp.dependency_instances.values.flatten.include?(k)
                is_app_specified = false
                other_connections.values.each{ |v|
                  is_app_specified = v.include?(pub_comp_name) and v.include?(sub_comp.name)
                  break if is_app_specified
                }
                
                if is_direct_dependency or is_app_specified
                  pub = ConnectionEndpoint.new(pub_group, pub_comp_name, pub_conn_name)
                  sub = ConnectionEndpoint.new(gn,k,cname)
                  conn_name = "conn_#{conn_id}"
                
                  d.connections[conn_name] = Connection.new(conn_name, pub, sub)  
                  conn_id = conn_id + 1  
                end
              }
            }
          }
        }
        
        d
      end
    end
  end
end