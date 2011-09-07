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

module Openshift::SDK::Controller
  class NodeApplicationDelegate
    include Object::Singleton
    
    def create(application)
      profile = application.descriptor.profiles[application.active_profile]
      profile.groups.each do |gname, group|
        pgroup = Openshift::SDK::Model::ProvisioningGroup.find(group.provisioning_group)
        pgroup.nodes.each do |nguid|
          napp = Openshift::SDK::Model::NodeApplication.find(application.node_application_map[nguid], application.user_group_id)
          unless napp
            napp = Openshift::SDK::Model::NodeApplication.new(application.guid,application.user_group_id)
            napp.gen_uuid
            application.node_application_map[nguid] = napp.guid
            napp.save!
            application.save!
          end
          napp.create!          
        end
      end
    end
    
    def destroy(application)
    end
  end
end
