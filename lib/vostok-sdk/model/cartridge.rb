require 'rubygems'
require 'active_model'
require 'json'
require 'vostok-sdk/config'

module Vostok
  module SDK
    class Cartridge
      include ActiveModel::Validations
      include ActiveModel::Serializers::JSON
      include ActiveModel::Serializers::Xml
      validates_presence_of :name, :native_name, :package_root, :package_path, :summary, :version, :license, :provides_feature, :requires_feature, :requires
      
      attr_accessor :name, :native_name, :package_root, :package_path, :summary, :version, :license, :provides_feature, :requires_feature, :requires

      def initialize(cart_name, package_root=nil, package_path=nil,provides_feature=[],requires_feature=[],requires=[])
        @name = cart_name
        @package_root = package_root || Config.instance.get('package_root')
        @package_path = package_path || (@package_root + "/" + @name)
        @provides_feature = provides_feature
        @requires_feature = requires_feature
        @requires = requires
      end
      
      def attributes
        @attributes ||= {"name" => nil, "native_name" => nil, "package_root" => nil, "package_path" => nil, 
          "summary" => nil, "version" => nil, "license" => nil, "provides_feature" => nil, "requires_feature" => nil, 
          "requires" => nil}
      end
      
      def attributes=(attr)
        attr.each do |name,value|
          send("#{name}=",value)
        end
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
        package_path = nil if /is not installed/.match(package_path)
        Cartridge.from_rpm_info(rpm_name, package_info, package_deps, package_provides, package_path)
      end

      def self.from_rpm_info(rpm_name, package_info, package_deps, package_provides, package_path)
        package_root = File.dirname(package_path) if not package_path.nil?
        cartridge = Cartridge.new("dummy_name",package_root,package_path)
        cartridge.package_path = package_path
        cartridge.package_root = package_root
        cartridge.native_name = rpm_name.strip

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

      def self.from_vpm(package_path)
        package_root = File.dirname(package_path)
        cartridge = Cartridge.new("dummy_name",package_root,package_path)
        control_spec = File.open(package_path + "/vostok/control.spec")
        control_spec.each{|line|
          val = line.split(/:/)[1]
          if not val.nil?
            val.strip!
            case line
              when /^Summary:/
                cartridge.summary = val
              when /^Name:/
                cartridge.name = val
              when /^Version:/
                cartridge.version = val
              when /^License:/
                cartridge.license = val
              when /^Provides:/
                cartridge.provides_feature = val.split(/,[ ]*/)
              when /^Requires:/
                cartridge.requires_feature = val.split(/,[ ]*/)
              when /^Native-Requires:/
                cartridge.requires.push(val)
            end
          end
        }
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
end
