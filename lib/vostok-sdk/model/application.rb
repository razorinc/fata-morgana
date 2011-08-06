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
      ds_attr_accessor :state, :deploy_state, :artifact_available
      
      state_machine :state, :initial => :not_created do
        transition :not_created => :creating, :on => :create
        transition :creating => :created, :on => :create_complete
        transition :created => :installing, :on => :install
        transition :installing => :stopped, :on => :install_complete
        transition :stopped => :starting, :on => :start
        transition :starting => :started, :on => :start_complete
        transition :started => :stopping, :on => :stop
        transition :stopping => :stopped, :on => :stop_complete
        transition :stopped => :uninstalling, :on => :uninstall
        transition :uninstalling => :created, :on => :uninstall_complete
        transition :created => :not_created, :on => :destroy
      end
        
      state_machine :deploy_state, :initial => :idle do
        transition :idle => :building, :on => :build, :if => :stopped? or :started? or :stopping? or :starting?
        transition :building => :idle, :on => :build_complete
        transition :idle => :deploying, :on => :deploy, :if => :artifact_available?
        transition :deploying => :idle, :on => :deploy_complete
      end
      
      def initialize(app_name=nil,package_root=nil,package_path=nil)
        super(app_name,package_root,package_path)
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
    end
  end
end