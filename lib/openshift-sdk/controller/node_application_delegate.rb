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
require 'singleton'
require 'openshift-sdk/config'
require 'openshift-sdk/utils/logger'
require 'openshift-sdk/model/node'
require 'openshift-sdk/model/application'
require 'openshift-sdk/model/node_application'

module Openshift
  module SDK
    module Controller
      class NodeApplicationDelegate
        include Object::Singleton
        attr_reader :nodes

        def initialize
          node = Model::Node.find("1") || Model::Node.new("1")
          node.save!
          @nodes = [node]          
        end
        
        def elect_node
          @nodes[0]
        end
        
        def create(application)
          #create the application on all nodes
          @nodes.each do |node|
            #use REST or dbus or mcollective here
            napp = Model::NodeApplication.new application.guid
            napp.gen_uuid
            napp.save!
            
            node[application.guid] = napp.guid
            node.save!
            napp.create!
            
            #connect all node local repositories to each other
            #napp.connect_repository_remotes Model::Node.find_all
          end
          
          #import the application code on an elected node
          #node = elect_node
           
          
          #replicate application code to all nodes
        end
        
        def install(application)
          napp_guid = node[application.guid]
          napp = Model::NodeApplication.find(napp_guid)
          napp.install!
        end
        
        def start(application)
          napp_guid = node[application.guid]
          napp = Model::NodeApplication.find(napp_guid)
          napp.start!
        end
        
        def stop(application)
          napp_guid = node[application.guid]
          napp = Model::NodeApplication.find(napp_guid)
          napp.stop!
        end
        
        def uninstall(application)
          napp_guid = node[application.guid]
          napp = Model::NodeApplication.find(napp_guid)
          napp.uninstall!
        end
        
        def destroy(application)
          napp_guid = node[application.guid]
          napp = Model::NodeApplication.find(napp_guid)
          napp.destroy!
          node.delete(application.guid)
          node.save!
        end
      end
    end
  end
end