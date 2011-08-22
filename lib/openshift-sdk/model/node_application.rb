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
require 'json'
require 'state_machine'
require 'openshift-sdk/config'
require 'openshift-sdk/model/application'
require 'openshift-sdk/model/model'

module Openshift
  module SDK
    module Model
      class NodeApplication  < OpenshiftModel
        ds_attr_accessor :state, :user, :deleted, :app_guid,:app_shared_repo_subdir, :app_prod_repo_subdir, :app_prod_subdir
        
        state_machine :state, :initial => :not_created, :action => :save! do
          event(:create) { transition :not_created => :creating }
          event(:create_complete) { transition :creating => :created }
          event(:create_error) { transition :creating => :destroying }
          event(:install) { transition :created => :installing }
          event(:install_error) { transition :installing => :created }
          event(:install_complete) { transition :installing => :stopped }
          event(:start) { transition :stopped => :starting }
          event(:start_complete) { transition :starting => :started }
          event(:stop) { transition :started => :stopping }
          event(:stop_complete) { transition :stopping => :stopped }
          event(:uninstall) { transition :stopped => :uninstalling }
          event(:uninstall_complete) { transition :uninstalling => :created }
          event(:destroy) { transition :created => :destroying }
          event(:destroy_complete) { transition :destroying => :not_created }
        end
          
        def initialize(app_guid=nil)
          super()
          self.app_guid = app_guid
          self.deleted = "false"
          self.app_shared_repo_subdir = ""
          self.app_prod_repo_subdir = ""
          self.app_prod_subdir = ""
          self.user = nil
        end
        
        def delete!
          self.deleted = "true"
          super
        end
        
        def save!
          super unless self.deleted == "true"
        end
      end
    end
  end
end
