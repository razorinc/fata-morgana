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

module Openshift::SDK::Model
  class Application < Cartridge
    ds_attr_accessor :state, :deploy_state, :artifact_available, :active_profile, :deleted, :descriptor, :users, :user_group_id, :interfaces
    
    state_machine :state, :initial => :not_created do
      event(:create) { transition :not_created => :creating }
      event(:create_complete) { transition :creating => :created }
      event(:create_error) { transition :creating => :destroying }
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
    
    def self.bucket
      `id -g`.strip
    end
    
    def initialize(app_name=nil,package_path=nil)
      super(app_name,package_path)
      self.users = []
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
    
    def delete!
      self.deleted = "true"
      super
    end
    
    def save!
      super(@user_group_id) unless self.deleted == "true" or @user_group_id.nil? 
      self
    end
  end
end
