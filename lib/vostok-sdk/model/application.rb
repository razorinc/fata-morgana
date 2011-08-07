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
require 'vostok-sdk/model/cartridge'
require 'vostok-sdk/model/model'
require 'vostok-sdk/model/app_descriptor'

module Vostok
  module SDK
    class Application  < Cartridge
      ds_attr_accessor :state, :deploy_state, :artifact_available, :user, :deleted
      
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
        
      state_machine :deploy_state, :initial => :idle, :action => :save! do
        transition :idle => :building, :on => :build, :if => :stopped? or :started? or :stopping? or :starting?
        transition :building => :idle, :on => :build_complete
        transition :idle => :deploying, :on => :deploy, :if => :artifact_available?
        transition :deploying => :idle, :on => :deploy_complete
      end
      
      def initialize(app_name=nil,package_root=nil,package_path=nil)
        super(app_name,package_root,package_path)
        deleted = "false"
      end
      
      def self.from_vpm(package_path)
        package_root = File.dirname(package_path)
        app = Application.new(nil,package_root,package_path)
        control_spec = File.open(package_path + "/vostok/control.spec")        
        app.from_vpm_spec(control_spec)
        app.native_name = app.name
        app.provides_feature = [app.name]
        app
      end
      
      def descriptor
        AppDescriptor.load_descriptor(self)
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