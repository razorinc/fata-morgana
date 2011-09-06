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
require 'openshift-sdk/config'
require 'openshift-sdk/model/model'
require 'openshift-sdk/model/rpm'
require 'openshift-sdk/model/descriptor'

module Openshift::SDK::Model
  class CartridgeNotInstalledException < Exception
  end
  
  class InvalidDescriptorException < Exception
  end
  
  class Cartridge < OpenshiftModel
    ds_attr_accessor :name, :version, :architecture, :display_name, :summary, :vendor, :license
    ds_attr_accessor :provides_feature, :requires_feature, :conflicts_feature, :requires
    ds_attr_accessor :package_path, :descriptor, :is_installed, :hooks
    
    def self.bucket
      "admin"
    end
  
    def initialize(cart_name="",package_path=nil,provides_feature=[],requires_feature=[],requires=[],is_installed=false,hooks=[])
      @name = cart_name
      @version = "0.0"
      @architecture = "noarch"
      package_root = Openshift::SDK::Config.instance.get('package_root')
      @package_path = package_path
      if @name
        @package_path = package_path || (package_root + "/" + @name)
      end
      @provides_feature = provides_feature
      @requires_feature = requires_feature
      @conflicts_feature = []
      @requires = requires
      @is_installed = is_installed
      @hooks = hooks
      @summary = ""
      @descriptor = nil
    end
    
    def installed?
      @is_installed
    end
    
    def descriptor
      @descriptor
    end
  
    def self.list_installed
      Cartridge.what_provides("openshift-feature-*").delete_if{ |c| !c.installed? }
    end
  
    def self.list_available
      Cartridge.what_provides("openshift-feature-*")
    end
  
    def self.what_provides(feature)
      feature = "openshift-feature-#{feature}" unless /^openshift-feature-/.match(feature)
      rpms = RPM.what_provides(feature)
      rpms.map! do |rpm|
        from_rpm(rpm)
      end
    end
  
    def self.from_rpm(rpm)
      cart = nil
      if rpm.is_installed
        cart = Cartridge.new.from_package_yaml(rpm.manifest)
        cart.package_path = File.dirname(File.dirname(rpm.control)) 
        cart.is_installed = true
        cart.hooks = rpm.hooks
      else
        package_path = nil
        
        provides_feature = rpm.provides.delete_if{ |f| !f.match(/openshift-feature-*/) }
        requires = rpm.dependencies.clone.delete_if{ |f| f.match(/openshift-feature-*/) }
        requires_feature = rpm.dependencies - requires

        provides_feature.map!{ |f| f[18..-1] }
        requires_feature.map!{ |f| f[18..-1] }

        cart_name = rpm.name.gsub(/-#{rpm.version}[0-9a-z\-\.]*/,"")
        cart = Cartridge.new(cart_name,package_path,package_path,provides_feature,requires_feature,requires,rpm.is_installed,rpm.hooks)
        cart.version = rpm.version
        cart.summary = rpm.summary
      end
      cart.guid="#{cart.name}-#{cart.version}"      
                  
      #lookup from dds or create new entry
      dds_cart = self.find(cart.guid)
      if !dds_cart || (!dds_cart.installed? && cart.installed?)
        if cart.installed?
          cart.descriptor
        end
        cart.save!
        dds_cart = cart
      end
        
      dds_cart
    end
    
    def load_descriptor(desc_hash)
      self.descriptor = Descriptor.new
      self.descriptor.from_descriptor_hash(desc_hash, self.requires_feature)
    end
  
    def from_manifest_yaml(yaml=nil)
      unless yaml
        #create a new control spec
        control_spec = File.open(self.package_path + "/openshift/package.yml", "w")
        control_spec.write(to_package_yaml)
        control_spec.close
      end
      
      spec_objects = {}
      case yaml.class.name
        when "Hash"
          spec_objects = yaml
        when "File"
          spec_objects  = YAML::load(yaml)
        else
          spec_objects  = YAML::load(File.open(yaml, "r").read)
      end
      
      self.name = spec_objects["Name"]
      self.version = spec_objects["Version"] || "0.0"
      self.architecture = spec_objects["Architecture"] || "noarch"
      self.display_name = spec_objects["Display Name"] || spec_objects["Name"]
      self.summary = spec_objects["Description"]
      self.vendor = spec_objects["Vendor"]
      self.license = spec_objects["License"] || "unknown"
      self.provides_feature = spec_objects["Provides"] || []
      self.requires_feature = spec_objects["Requires"] || []
      self.conflicts_feature = spec_objects["Conflicts"] || []      
      self.requires = spec_objects["Native Requires"] || []
      self.load_descriptor(spec_objects["Descriptor"] || {})
      
      self
    end
  
    def to_manifest_yaml
      yaml_hash = {}
      yaml_hash["Name"]             = self.name
      yaml_hash["Version"]          = self.version || "0.0"
      yaml_hash["Architecture"]     = self.architecture || "noarch"
      yaml_hash["Display Name"]     = self.display_name || "#{self.name}-#{self.version}-#{self.architecture}"
      yaml_hash["Description"]      = self.summary || "."
      yaml_hash["Vendor"]           = self.vendor
      yaml_hash["License"]          = self.license || "unknown"
      yaml_hash["Provides"]         = self.provides_feature || []
      yaml_hash["Requires"]         = self.requires_feature || []
      yaml_hash["Conflicts"]        = self.conflicts_feature || []
      yaml_hash["Native Requires"]  = self.requires

      if @is_installed
        yaml_hash['Descriptor'] = self.descriptor.to_descriptor_hash
      else
        yaml_hash['Descriptor'] = {}
      end
      
      yaml_hash.to_yaml
    end

    def self.from_opm(package_path)
      cartridge = Cartridge.new(nil,package_path)
      manifest = File.open(package_path + "/openshift/manifest.yml")
      cartridge.from_manifest_yaml(manifest)
      cartridge.is_installed = true
      cartridge
    end
    
    def to_s
      to_package_yaml
    end
  end
end
