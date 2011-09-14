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
require 'openshift-sdk/controller/node_application_delegate'

module Openshift::SDK::Model
  class Application < Cartridge
    ds_attr_accessor :state, :deploy_state, :artifact_available, :active_profile, :descriptor, :users, :user_group_id, :interfaces,
                     :node_application_map, :component_instance_map
    
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
      self.node_application_map = {}
      self.component_instance_map = {}
    end
    
    def gen_empty_descriptor
      from_manifest_yaml("Name: #{self.name}")
    end
    
    def attributes
      {"state"=> @state, "deploy_state"=> @deploy_state, "descriptor" => self.descriptor}
    end
    
    def build_component_instance_map(cart=self, prof=nil, prefix="")
      cart_prefix = ""
      unless cart.class == Application
        cart_prefix = cart.name
        cart_prefix = prefix + "." + cart_prefix unless prefix.nil? or prefix == ""
        self.component_instance_map[cart_prefix] = cart
      end
      
      cart.descriptor.profiles[prof].groups.each do |gname, group|
        group.resolved_components.each do |comp_name, comp|
          comp_prefix = comp_name
          comp_prefix = cart_prefix + "." + comp_prefix unless cart_prefix == "" or cart_prefix.nil?

          self.component_instance_map[comp_prefix] = comp
          comp.mapped_name = comp_prefix
          comp.cartridge_instances.each do |cpname,cpobj|
            build_component_instance_map(cpobj.cartridge, cpobj.profile, comp_prefix)
          end
        end
      end
    end
    
    def self.from_opm(package_path)
      app = Application.new(nil,package_path)
      manifest = File.open(package_path + "/openshift/manifest.yml")
      app.from_manifest_yaml(manifest)
      app.is_installed = true
      app
    end
    
    def resolve_references(profile_name = nil)
      self.active_profile= profile_name || "default"
      super
      build_component_instance_map(self,self.active_profile,"")
    end
    
    def delete!
      super(@user_group_id) unless @user_group_id.nil? 
      self
    end
    
    def save!
      super(@user_group_id) unless @user_group_id.nil? 
      self
    end
    
    def add_feature(feature, is_native)
      Openshift::SDK::Controller::NodeApplicationDelegate.instance.add_feature(self,feature, is_native)
    end
  end
end
