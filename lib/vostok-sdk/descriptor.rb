require 'rubygems'
require 'vostok-sdk/config'
require 'vostok-sdk/json'
require 'vostok-sdk/cartridge'

module Vostok
  module SDK
    class AppDescriptor
      attr_accessor :groups, :connections, :app
      include Vostok::SDK::JSONEncodable

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
    
    class Connection
      attr_accessor :name, :pub, :sub
      include Vostok::SDK::JSONEncodable
      
      def initialize(name,pub,sub)
        @name, @pub, @sub = name, pub, sub
      end
    end
    
    class ConnectionEndpoint
      attr_accessor :group_name, :component_name, :connector_name
      include Vostok::SDK::JSONEncodable
      
      def initialize(group_name, component_name, connector_name)
        @group_name, @component_name, @connector_name= group_name, component_name, connector_name
      end
    end

    class Group
      attr_accessor :name, :components
      include Vostok::SDK::JSONEncodable

      def self.load_descriptor(name,json_data,app_descriptor)
        g = Group.new
        g.name=name
        
        g.components = {}
        if json_data["components"]
          json_data["components"].each{|k,v|
            g.components[k] = ComponentInstance.load_descriptor(k,v)
          }
        else
          app = app_descriptor.app
          app.requires_feature.each{ |feature|
            f_inst, f_dep_cmap = ComponentInstance.from_app_dependency(feature)
            g.components.merge!(f_dep_cmap)
          }
        end
        g
      end
    end
    
    class ComponentInstance
      attr_accessor :name, :feature, :cartridge, :component, :profile_name, :dependency_instances
      include Vostok::SDK::JSONEncodable
      
      def initialize
        @dependency_instances = {}
      end
      
      def self.from_app_dependency(feature)
        cartridge = Cartridge.what_provides(feature)[0]
        cart_descriptor = Descriptor.load_descriptor(cartridge)
        profile_name = cart_descriptor.profiles.keys[0]
        
        cmap = {}
        direct_deps = []
        cart_descriptor.profiles[profile_name].components.each{ |k,v|
          c = ComponentInstance.new
          c.feature = c.name = v.feature
          c.cartridge = cartridge
          c.component = v
          c.profile_name = profile_name
          cmap[c.name] = c
          
          cartridge.requires_feature.each{ |f|
            f_inst, f_dep_cmap = ComponentInstance.from_app_dependency(f)
            c.dependency_instances[f] = f_inst
            cmap.merge!(f_dep_cmap)
          }
          direct_deps.push(c.name)
        }
        
        return direct_deps, cmap
      end
      
      def self.load_descriptor(name,json_data)
        c = ComponentInstance.new
        c.name = name
        c.feature = json_data["feature"]
        cartridge_name = json_data["cartridge_name"]
        if cartridge_name
          c.cartridge = Cartridge.from_rpm(cartridge_name)
        else
          c.cartridge = Cartridge.what_provides(c.feature)[0]  
        end
        cart_descriptor = Descriptor.load_descriptor(c.cartridge)
        c.profile_name = json_data["profile_name"] || cart_descriptor.profiles.keys[0]
        c.component = cart_descriptor.profiles[c.profile_name].components[c.feature]

        c
      end      
    end

    class Descriptor
      attr_accessor :profiles, :cartridge
      include Vostok::SDK::JSONEncodable

      def self.load_descriptor(cartridge)
        d = Descriptor.new
        d.cartridge = cartridge
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

    class Profile
      attr_accessor :name, :components, :connections
      include Vostok::SDK::JSONEncodable

      def self.load_descriptor(name,json_data,cartridge)
        p = Profile.new
        p.name=name
        
        p.components = {}
        if json_data.has_key?("components")
          json_data["components"].each{|k,v|
            p.components[k] = Component.load_descriptor(k,v)
          }
        else
          feature_name = cartridge.provides_feature[0]
          p.components[feature_name] = Component.load_descriptor(feature_name,json_data)
        end
        
        p
      end
    end

    class Component
      attr_accessor :feature, :publishes, :subscribes
      include Vostok::SDK::JSONEncodable

      def self.load_descriptor(feature,json_data)
        publishes = json_data["connectors"]["publishes"]
        subscribes = json_data["connectors"]["subscribes"]
        
        c = Component.new
        c.feature = feature

        c.publishes = {}
        if publishes
          publishes.each{|k,v|
            c.publishes[k] = Connector.load_descriptor(k,v,:publisher)
          }
        end

        c.subscribes = {}
        if subscribes
          subscribes.each{|k,v|
            c.subscribes[k] = Connector.load_descriptor(k,v,:subscriber)
          }
        end
        
        c
      end
    end

    class Connector
      attr_accessor :type, :pubsub, :name, :required
      include Vostok::SDK::JSONEncodable
      
      def self.load_descriptor(id,json_data, pubsub)
        c = Connector.new
        c.type = json_data['type'] if pubsub == :publisher
        c.type = json_data['required-type'] if pubsub == :subscriber
        c.pubsub = pubsub
        c.name = id
        c.required = json_data['required'] || false
        c
      end

      def required?
        return @required
      end
    end
  end
end
