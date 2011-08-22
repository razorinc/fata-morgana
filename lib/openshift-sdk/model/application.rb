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
require 'openshift-sdk/model/cartridge'
require 'openshift-sdk/model/model'
require 'openshift-sdk/model/app_descriptor'

module Openshift
  module SDK
    module Model
      class Application < Cartridge
        ds_attr_accessor :state, :deploy_state, :artifact_available, :deleted, :descriptor
        
        state_machine :state, :initial => :not_created, :action => :save! do
          event(:create) { transition :not_created => :creating }
          event(:create_complete) { transition :creating => :created }
          event(:create_error) { transition :creating => :destroying }
          event(:install) { transition :created => :installing }
          event(:install_complete) { transition :installing => :stopped }
          event(:install_error) { transition :installing => :created }
          event(:start) { transition :stopped => :starting }
          event(:start_complete) { transition :starting => :started }
          event(:stop) { transition :started => :stopping }
          event(:stop_complete) { transition :stopping => :stopped }
          event(:uninstall) { transition :stopped => :uninstalling }
          event(:uninstall_complete) { transition :uninstalling => :created }
          event(:destroy) { transition :created => :destroying }
          event(:destroy_complete) { transition :destroying => :not_created }
        end
          
        state_machine :deploy_state, :initial => :idle, :action => :save! do
          event :build do
            transition :idle => :building, :if => :stopped? or :started? or :stopping? or :starting?
          end

          event :build_complete do
            transition :building => :idle
          end

          event :deploy do
            transition :idle => :deploying, :if => :artifact_available?
          end

          event :deploy_complete do
            transition :deploying => :idle
          end
        end
        
        def initialize(app_name=nil,package_root=nil,package_path=nil)
          super()          
          self.name,self.package_root,self.package_path = app_name,package_root,package_path
          self.deleted = "false"
        end
        
        def attributes
          {"state"=> @state, "deploy_state"=> @deploy_state, "deleted"=>@deleted, "descriptor" => self.descriptor}
        end
        
        def self.from_opm(package_path)
          package_root = File.dirname(package_path)
          app = Application.new(nil,package_root,package_path)
          control_spec = File.open(package_path + "/openshift/control.spec")        
          app.from_opm_spec(control_spec)
          app.native_name = app.name
          app.provides_feature = [app.name]
          app
        end
        
        def descriptor
          descriptor_changed = @descriptor.nil?
          @descriptor ||= AppDescriptor.load_descriptor(self)
          descriptor_will_change! if descriptor_changed
          @descriptor
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
