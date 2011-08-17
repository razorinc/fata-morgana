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
require 'vostok-sdk/config'
require 'vostok-sdk/model/model'
require 'vostok-sdk/model/descriptor'

module Vostok
  module SDK
    module Model
      class Cartridge < VostokModel
        validates_presence_of :name, :native_name, :package_root, :package_path, :summary, :version, :provides_feature
        ds_attr_accessor :name, :native_name, :package_root, :package_path, :summary, :version, :license, :provides_feature, :requires_feature, :requires, :descriptor
        attr_writer :is_installed
  
        def initialize(cart_name="", package_root=nil, package_path=nil,provides_feature=[],requires_feature=[],requires=[])
          @name = cart_name
          @package_root = package_root || Config.instance.get('package_root')
          @package_path = package_path
          if @name
            @package_path = package_path || (@package_root + "/" + @name)
          end
          @provides_feature = provides_feature
          @requires_feature = requires_feature
          @requires = requires
        end
        
        def installed?
          @is_installed
        end
        
        def descriptor
          self.descriptor ||= Descriptor.load_descriptor(self)
        end
  
        def self.list_installed
          Cartridge.what_provides("openshift-feature-*").delete_if{ |c| c.package_path.nil? }
        end
  
        def self.list_available
          Cartridge.what_provides("openshift-feature-*")
        end
  
        def self.what_provides(feature)
          if not /^openshift-feature-/.match(feature)
            feature = "openshift-feature-#{feature}"
          end
          rpms = `repoquery --envra --whatprovides #{feature}`
          
          cartridges = []
          rpms.each{|rpm|
            rpm = rpm.split(/:/)
            cartridges.push(Cartridge.from_rpm(rpm[1]))
          }
  
          cartridges
        end
  
        def self.from_rpm(rpm_name)
          package_info = `repoquery --info #{rpm_name}`
  
          package_deps = `yum deplist #{rpm_name}`.split("\n").delete_if{ |i| not /dependency:/.match(i) }
          package_provides = `repoquery --provides #{rpm_name}`.split("\n")
  
          package_path = `rpm -q --queryformat='%{FILENAMES}' #{rpm_name}`
          is_installed = true
          if /is not installed/.match(package_path)
            package_path = nil
            is_installed = false
          end 
          Cartridge.from_rpm_info(rpm_name, package_info, package_deps, package_provides, package_path, is_installed)
        end
  
        def self.from_rpm_info(rpm_name, package_info, package_deps, package_provides, package_path, is_installed)
          package_root = File.dirname(package_path) if not package_path.nil?
          cartridge = Cartridge.new("dummy_name",package_root,package_path)
          cartridge.package_path = package_path
          cartridge.package_root = package_root
          cartridge.native_name = rpm_name.strip
          cartridge.is_installed = is_installed
  
          package_info.each{|line|
            val = line.split(/:/)[1]
            if not val.nil?
              val.strip!
              case line
                when /^Summary/
                  cartridge.summary = val
                when /^Name/
                  cartridge.name = val
                when /^Version/
                  cartridge.version = val
              end
            end
          }
          package_deps.each{|dep|
              dep.gsub!(/[ ]*dependency:[ ]*/, "")
              if /^openshift-feature-/.match(dep)
                cartridge.requires_feature.push(dep.sub(/^openshift-feature-/,""))
              else
                cartridge.requires.push(dep)
              end
          }
          package_provides.each{|req|
            cartridge.provides_feature.push(req.sub(/^openshift-feature-/,"")) if req.match(/^openshift-feature-/)
          }
          cartridge
        end
        
        def from_vpm_spec(control_spec)
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
  
        def self.from_vpm(package_path)
          package_root = File.dirname(package_path)
          cartridge = Cartridge.new(nil,package_root,package_path)
          control_spec = File.open(package_path + "/vostok/control.spec")        
          cartridge.from_vpm_spec(control_spec)
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
  end
end
