require 'rubygems'
require 'vostok-sdk/config'
require 'vostok-sdk/model/cartridge'

module Vostok
  module SDK
    module Utils
      class Rpm
        def self.add_to_repo(rpm_file)
          config = Vostok::SDK::Config.instance
          rpm_repo = config.get('rpm_repo')
          system "cp #{rpm_file} #{rpm_repo}"
          system "createrepo #{rpm_repo}"
        end
        
        def self.control_to_spec(vpm_dir)
          config = Vostok::SDK::Config.instance
          cart = Vostok::SDK::Cartridge.from_vpm(vpm_dir)
          
          provides_feature = cart.provides_feature.map{|f| "provides: openshift-feature-#{f}"}.join("\n")
          requires_feature = cart.requires_feature.map{|f| "requires: openshift-feature-#{f}"}.join("\n")
          requires = cart.requires.map{|f| "requires: #{f}"}.join("\n")

rpm_spec = <<-EOF
%define _topdir    /tmp/openshift-feature-#{cart.name}/
%define name      openshift-cartridge-#{cart.name}
%define release    1
%define version    #{cart.version}
%define buildroot %{_topdir}/%{name}-%{version}-root

BuildRoot:        %{buildroot}
Summary:          #{cart.summary}
Name:              %{name}
Version:          %{version}
Release:          %{release}
Source:            %{name}-%{version}.tar.gz
License:          #{cart.license}

#{provides_feature}
#{requires_feature}
#{requires}

BuildArch: noarch
Prefix:            /opt/vostok/cartridges
%description
Openshift %{name}-%{version} feature

%prep
%setup -q

%build

%install
pwd
ls -la
mkdir -p $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/opt/vostok/cartridges/%{name}-%{version}
cp -r * $RPM_BUILD_ROOT/opt/vostok/cartridges/%{name}-%{version}
find $RPM_BUILD_ROOT/opt/vostok/cartridges/%{name}-%{version} | sed -e s\\|$RPM_BUILD_ROOT\\|\\| > files.txt

%files -f files.txt
EOF

          spec_file = "#{vpm_dir}/vostok/#{cart.name}.spec"
          rpm_spec_file = File.open(spec_file,"w")
          rpm_spec_file.write(rpm_spec)
          rpm_spec_file.flush
          rpm_spec_file.close
          return spec_file
        end
        
        def self.create_rpm(vpm_dir)
          config = Vostok::SDK::Config.instance
          cart = Vostok::SDK::Cartridge.from_vpm(vpm_dir)
          spec_file = "#{vpm_dir}/vostok/#{cart.name}.spec"
          if not File.exists?(spec_file)
            system("vpm-control-to-spec #{vpm_dir}")
          end
          
          system("mkdir -p /tmp/openshift-feature-#{cart.name}")
          system("cd /tmp/openshift-feature-#{cart.name}; mkdir -p BUILD RPMS SOURCES SPECS SRPMS")
          system("cp #{vpm_dir}/vostok/#{cart.name}.spec /tmp/openshift-feature-#{cart.name}/SPECS/")
          system("mkdir -p /tmp/openshift-feature-#{cart.name}/SOURCES/openshift-cartridge-#{cart.name}-#{cart.version}/")
          system("cp -r #{vpm_dir}/* /tmp/openshift-feature-#{cart.name}/SOURCES/openshift-cartridge-#{cart.name}-#{cart.version}/")
          system("cd /tmp/openshift-feature-#{cart.name}/SOURCES; tar zcf openshift-cartridge-#{cart.name}-#{cart.version}.tar.gz openshift-cartridge-#{cart.name}-#{cart.version}")
          system("cd /tmp/openshift-feature-#{cart.name}; rpmbuild -v -ba SPECS/#{cart.name}.spec 2>&1 > /dev/null")
          return "/tmp/openshift-feature-#{cart.name}/RPMS/noarch/openshift-cartridge-#{cart.name}-#{cart.version}-1.noarch.rpm"
        end
      end
    end
  end
end