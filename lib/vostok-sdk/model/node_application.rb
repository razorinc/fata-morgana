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
require 'vostok-sdk/config'
require 'vostok-sdk/model/application'
require 'vostok-sdk/model/model'

module Vostok
  module SDK
    module Model
      class NodeApplication  < VostokModel
        ds_attr_accessor :state, :user, :deleted, :app_guid,:app_shared_repo_subdir, :app_prod_repo_subdir, :app_prod_subdir
        
        state_machine :state, :initial => :not_created, :action => :save! do
          transition :not_created => :creating, :on => :create
          transition :creating => :created, :on => :create_complete
          transition :creating => :destroying, :on => :create_error
          transition :created => :installing, :on => :install
          transition :installing => :stopped, :on => :install_complete
          transition :stopped => :starting, :on => :start
          transition :starting => :started, :on => :start_complete
          transition :started => :stopping, :on => :stop
          transition :stopping => :stopped, :on => :stop_complete
          transition :stopped => :uninstalling, :on => :uninstall
          transition :uninstalling => :created, :on => :uninstall_complete
          transition :created => :destroying, :on => :destroy
          transition :destroying => :not_created, :on => :destroy_complete
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