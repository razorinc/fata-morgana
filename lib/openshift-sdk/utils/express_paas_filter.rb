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

require 'openshift-sdk/model/node'
require 'openshift-sdk/model/cluster'
require 'openshift-sdk/model/provisioning_group'
module Openshift::SDK::Utils
  class ExpressPaasFilter
    include Singleton
    
    def setup_cluster
      cluster = Openshift::SDK::Model::Cluster.instance
      if( cluster.provisioning_groups.size == 0)
        pgrp = Openshift::SDK::Model::ProvisioningGroup.new
        pgrp.nodes = [Openshift::SDK::Model::Node.this_node.guid]
        pgrp.save!
        cluster.add_provisioning_group pgrp.guid
        cluster.save!
      end
    end
    
    def map_application_group(agrp)
      cluster = Openshift::SDK::Model::Cluster.instance      
      cluster.provisioning_groups[0]
    end
    
    def scale_up(pgroup_guid)
      #no-op
    end
  end
end