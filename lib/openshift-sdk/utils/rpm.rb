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
require 'openshift-sdk/config'
require 'openshift-sdk/model/cartridge'

module Openshift
  module SDK
    module Utils
      class Rpm
        def self.add_to_repo(rpm_file)
          config = Openshift::SDK::Config.instance
          rpm_repo = config.get('rpm_repo')
          system "cp #{rpm_file} #{rpm_repo}"
          system "createrepo #{rpm_repo}"
        end
        
        def self.control_to_spec(opm_dir)
          config = Openshift::SDK::Config.instance
          cart = Openshift::SDK::Model::Cartridge.from_opm(opm_dir)
          
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
Prefix:            /opt/openshift/cartridges
%description
Openshift %{name}-%{version} feature

%prep
%setup -q

%build

%install
pwd
ls -la
mkdir -p $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/opt/openshift/cartridges/%{name}-%{version}
cp -r * $RPM_BUILD_ROOT/opt/openshift/cartridges/%{name}-%{version}
find $RPM_BUILD_ROOT/opt/openshift/cartridges/%{name}-%{version} | sed -e s\\|$RPM_BUILD_ROOT\\|\\| > files.txt

%files -f files.txt
EOF

          spec_file = "#{opm_dir}/openshift/#{cart.name}.spec"
          rpm_spec_file = File.open(spec_file,"w")
          rpm_spec_file.write(rpm_spec)
          rpm_spec_file.flush
          rpm_spec_file.close
          return spec_file
        end
        
        def self.create_rpm(opm_dir)
          config = Openshift::SDK::Config.instance
          cart = Openshift::SDK::Model::Cartridge.from_opm(opm_dir)
          spec_file = "#{opm_dir}/openshift/#{cart.name}.spec"
          if not File.exists?(spec_file)
            system("opm-control-to-spec #{opm_dir}")
          end
          
          system("mkdir -p /tmp/openshift-feature-#{cart.name}")
          system("cd /tmp/openshift-feature-#{cart.name}; mkdir -p BUILD RPMS SOURCES SPECS SRPMS")
          system("cp #{opm_dir}/openshift/#{cart.name}.spec /tmp/openshift-feature-#{cart.name}/SPECS/")
          system("mkdir -p /tmp/openshift-feature-#{cart.name}/SOURCES/openshift-cartridge-#{cart.name}-#{cart.version}/")
          system("cp -r #{opm_dir}/* /tmp/openshift-feature-#{cart.name}/SOURCES/openshift-cartridge-#{cart.name}-#{cart.version}/")
          system("cd /tmp/openshift-feature-#{cart.name}/SOURCES; tar zcf openshift-cartridge-#{cart.name}-#{cart.version}.tar.gz openshift-cartridge-#{cart.name}-#{cart.version}")
          system("cd /tmp/openshift-feature-#{cart.name}; rpmbuild -v -ba SPECS/#{cart.name}.spec 2>&1 > /dev/null")
          return "/tmp/openshift-feature-#{cart.name}/RPMS/noarch/openshift-cartridge-#{cart.name}-#{cart.version}-1.noarch.rpm"
        end
      end
    end
  end
end