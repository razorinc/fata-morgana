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
    ds_attr_accessor :name, :version, :architecture, :display_name, :summary, :vendor, :license,
                     :provides_feature, :requires_feature, :conflicts_feature, :requires,
                     :package_path, :descriptor, :is_installed, :hooks, :parent_instance
    
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
      @parent_instance = nil
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
        cart = from_opm(File.dirname(File.dirname(rpm.manifest)))
        cart.hooks = rpm.hooks
      else
        package_path = nil
        
        provides_feature = rpm.provides.delete_if{ |f| !f.match(/openshift-feature-*/) }
        requires = rpm.dependencies.clone.delete_if{ |f| f.match(/openshift-feature-*/) }
        requires_feature = rpm.dependencies - requires

        provides_feature.map!{ |f| f[18..-1] }
        requires_feature.map!{ |f| f[18..-1] }

        cart_name = rpm.name.gsub(/-#{rpm.version}[0-9a-z\-\.]*/,"").gsub("openshift-cartridge-","")
        cart = Cartridge.new(cart_name,package_path,provides_feature,requires_feature,requires,rpm.is_installed,rpm.hooks)
        cart.version = rpm.version
        cart.summary = rpm.summary
      end
      cart.guid="#{cart.name}-#{cart.version}"
      cart
    end
    
    def load_descriptor(desc_hash, resolve_references=false)
      self.descriptor = Descriptor.new(self)
      self.descriptor.from_descriptor_hash(desc_hash,self.requires_feature)
      self.descriptor.resolve_references if resolve_references
    end

    def resolve_references(profile_name = nil)
      if self.descriptor.nil?
        raise "Descriptor for cartridge #{self.name} not available. Cannot resolve references. Cartridge not installed?"
      end
      self.descriptor.resolve_references(profile_name)
    end
  
    def from_manifest_yaml(yaml=nil)
      unless yaml
        #create a new control spec
        control_spec = File.open(self.package_path + "/openshift/manifest.yml", "w")
        control_spec.write(to_manifest_yaml)
        control_spec.close
      end
      
      spec_objects = {}
      case yaml.class.name
        when "Hash"
          spec_objects = yaml
        when "File"
          spec_objects  = YAML::load(yaml)
        else
          if File.exists?(yaml)
            spec_objects  = YAML::load(File.open(yaml, "r").read)
          else
            spec_objects  = YAML::load(yaml)
          end
      end
      
      expected_keys = ["Name", "Version", "Architecture", "Display-Name", "Description", 
         "Vendor", "License", "Provides", "Requires", "Conflicts", "Native-Requires", "Descriptor", "Build-Arch"]
      unknown_keys = spec_objects.keys.clone - expected_keys
      if unknown_keys.size > 0
        log.error "Error parsing manifest.yml cartridge/application. Unexpected keys: [#{unknown_keys.join(",")}]. Allowed keys are [#{expected_keys.join(",")}]"
        raise "Error parsing manifest.yml cartridge/application. Unexpected keys: [#{unknown_keys.join(",")}]. Allowed keys are [#{expected_keys.join(",")}]"
      end
      
      self.name = spec_objects["Name"]
      self.version = spec_objects["Version"] || "0.0"
      self.architecture = spec_objects["Architecture"] || "noarch"
      self.display_name = spec_objects["Display-Name"] || spec_objects["Name"]
      self.summary = spec_objects["Description"] || spec_objects["Name"]
      self.vendor = spec_objects["Vendor"] || "unknown"
      self.license = spec_objects["License"] || "unknown"
      
      case spec_objects["Provides"]
      when Array
        self.provides_feature = spec_objects["Provides"]
      when String
        self.provides_feature = spec_objects["Provides"].split(",")
      else
        self.provides_feature = []
      end
      
      case spec_objects["Requires"]
      when Array
        self.requires_feature = spec_objects["Requires"]
      when String
        self.requires_feature = spec_objects["Requires"].split(",")
        self.requires_feature.map!{ |e| e.strip }        
        
      else
        self.requires_feature = []
      end
      
      case spec_objects["Conflicts"]
      when Array
        self.conflicts_feature = spec_objects["Conflicts"]
      when String
        self.conflicts_feature = spec_objects["Conflicts"].split(",")
        self.conflicts_feature.map!{ |e| e.strip }        
      else
        self.conflicts_feature = []
      end
      
      case spec_objects["Native-Requires"]
      when Array
        self.requires = spec_objects["Native-Requires"]
      when String
        self.requires = spec_objects["Native-Requires"].split(",")
        self.requires.map!{ |e| e.strip }
      else
        self.requires = []
      end
      self.load_descriptor(spec_objects["Descriptor"] || {})
      
      self
    end
  
    def to_manifest_yaml
      yaml_hash = {}
      yaml_hash["Name"]             = self.name
      yaml_hash["Version"]          = self.version || "0.0"
      yaml_hash["Architecture"]     = self.architecture || "noarch"
      yaml_hash["Display-Name"]     = self.display_name || "#{self.name}-#{self.version}-#{self.architecture}"
      yaml_hash["Description"]      = self.summary || "."
      yaml_hash["Vendor"]           = self.vendor
      yaml_hash["License"]          = self.license || "unknown"
      yaml_hash["Provides"]         = self.provides_feature || []
      yaml_hash["Requires"]         = self.requires_feature || []
      yaml_hash["Conflicts"]        = self.conflicts_feature || []
      yaml_hash["Native-Requires"]  = self.requires

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
    
    def get_profile_from_feature(feature_name)
      d = self.descriptor
      raise "Cartridge #{self.name} is not installed" if d.nil?
      # FIXME - find the correct profile for given feature_name
      case d.profiles
        when NilClass
          raise "Cartridge #{self.name} is not installed" if d.nil?
        when Array
          return d.profiles[0].name
        when Hash
          return d.profiles.keys[0]
        else
          raise "Cartridge #{self.name} cannot find a profile for #{feature_name}"
      end
    end

    def delete!(bucket=nil)
      super(bucket)
    end
    
    def package_root
      File.dirname @package_path
    end
  end
end
