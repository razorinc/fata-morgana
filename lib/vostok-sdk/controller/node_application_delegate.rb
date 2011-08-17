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
require 'vostok-sdk/config'
require 'vostok-sdk/utils/logger'
require 'vostok-sdk/model/node'
require 'vostok-sdk/model/application'
require 'vostok-sdk/model/node_application'

module Vostok
  module SDK
    module Controller
      class NodeApplicationDelegate
        include Object::Singleton
        attr_reader :node

        def initialize
          @node = Model::Node.find("1") || Model::Node.new("1")
          @node.save!
        end
        
        def create(application)
          napp = Model::NodeApplication.new application.guid
          napp.gen_uuid
          napp.save!
          node[application.guid] = napp.guid
          node.save!
          napp.create!
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