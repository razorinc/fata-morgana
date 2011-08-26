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
  class Cartridge < OpenshiftModel
    validates_presence_of :name, :native_name, :package_root, :package_path, :summary, :version, :provides_feature
    ds_attr_accessor :name, :native_name, :package_root, :package_path, :summary, :version, :license, :provides_feature, :requires_feature, :requires, :descriptor, :is_installed, :hooks 
    def self.bucket
      "admin"
    end
  
    def initialize(cart_name="", package_root=nil, package_path=nil,provides_feature=[],requires_feature=[],requires=[],is_installed=false,hooks=[])
      @name = cart_name
      @package_root = package_root || Openshift::SDK::Config.instance.get('package_root')
      @package_path = package_path
      if @name
        @package_path = package_path || (@package_root + "/" + @name)
      end
      @provides_feature = provides_feature
      @requires_feature = requires_feature
      @requires = requires
      @is_installed = is_installed
      @hooks = hooks
      @summary = ""
    end
    
    def installed?
      @is_installed
    end
    
    def descriptor
      return nil unless @is_installed
      descriptor_changed = @descriptor.nil?
      @descriptor ||= Descriptor.new(self)
      descriptor_will_change! if descriptor_changed
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
      if rpm.control
        package_path = File.dirname(File.dirname(rpm.control)) 
        package_root = File.dirname package_path
      else
        package_root = package_path = nil
      end
      provides_feature = rpm.provides.delete_if{ |f| !f.match(/openshift-feature-*/) }
      requires = rpm.dependencies.clone.delete_if{ |f| f.match(/openshift-feature-*/) }
      requires_feature = rpm.dependencies - requires
      
      provides_feature.map!{ |f| f[18..-1] }
      requires_feature.map!{ |f| f[18..-1] }
      
      cart_name = rpm.name.gsub(/-#{rpm.version}[0-9a-z\-\.]*/,"")
      cart = Cartridge.new(cart_name,package_root,package_path,provides_feature,requires_feature,requires,rpm.is_installed,rpm.hooks)
      cart.version = rpm.version
      cart.summary = rpm.summary
      cart.native_name = rpm.name
      cart.guid="#{cart.name}-#{cart.version}"
                  
      #lookup from dds or create new entry
      dds_cart = self.find("#{rpm.name}-#{rpm.version}")
      if !dds_cart || (!dds_cart.installed? && cart.installed?)
        if cart.installed?
          cart.descriptor
        end
        cart.save!
        dds_cart = cart
      end
        
      dds_cart
    end
  
    def from_opm_spec(control_spec)
      control_spec.each{|line|
        val = line.split(/:/)[1]
        if not val.nil?
          val.strip!
          case line
            when /^Summary:/
              self.summary = val
            when /^Name:/
              self.name = val
            when /^Version:/
              self.version = val
            when /^License:/
              self.license = val
            when /^Provides:/
              self.provides_feature = val.split(/,[ ]*/)
            when /^Requires:/
              self.requires_feature = val.split(/,[ ]*/)
            when /^Native-Requires:/
              self.requires.push(val)
          end
        end
      }
      self
    end
  
    def self.from_opm(package_path)
      package_root = File.dirname(package_path)
      cartridge = Cartridge.new(nil,package_root,package_path)
      control_spec = File.open(package_path + "/openshift/control.spec")        
      cartridge.from_opm_spec(control_spec)
      cartridge.is_installed = true
      cartridge
    end
  
    def to_s
    str = <<-EOF

  Name: #{name}
  Native name: #{native_name}
  Package root: #{package_root}
  Package path: #{package_path}
  Summary: #{summary.strip}
  Version: #{version}
  License: #{license}
  Provides feature: #{provides_feature.join(", ")}
  Requires feature: #{requires_feature.join(", ")}
  Native requires: #{requires.join(", ")}
EOF
    end
  end
end
