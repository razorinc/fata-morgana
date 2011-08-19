%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname openshift
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        OpenShift SDK
Name:           rubygem-%{gemname}
Version:        0.1.0
Release:        1%{?dist}
Group:          Development/Languages
License:        AGPLv3
URL:            http://openshift.redhat.com
Source0:        http://gems.rubyforge.org/gems/%{gemname}-%{version}.gem
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       rubygems(activemodel)
Requires:       rubygems(highline)
Requires:       rubygems(json_pure)
Requires:       rubygems(parseconfig)
Requires:       rubygems(sqlite3)
BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       ruby(%{gemname}) = %version

%description
This contains the OpenShift Software Development Kit packaged as a rubygem.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
gem install --local --install-dir %{buildroot}%{gemdir} --force %{SOURCE0}
mkdir -p %{buildroot}/%{_bindir}
mv %{buildroot}%{gemdir}/bin/* %{buildroot}/%{_bindir}
rmdir %{buildroot}%{gemdir}/bin

%clean
rm -rf %{buildroot}                                

%files
%defattr(-,root,root,-)
%{_bindir}/vpm
%{_bindir}/vpm-add-to-repo
%{_bindir}/vpm-build
%{_bindir}/vpm-control-to-spec
%{_bindir}/vpm-create
%{_bindir}/vpm-create-rpm
%{_bindir}/vpm-deploy
%{_bindir}/vpm-destroy
%{_bindir}/vpm-export
%{_bindir}/vpm-help
%{_bindir}/vpm-inspect
%{_bindir}/vpm-inspect-descriptor
%{_bindir}/vpm-install
%{_bindir}/vpm-list-applications
%{_bindir}/vpm-list-available-cartridges
%{_bindir}/vpm-list-installed-cartridges
%{_bindir}/vpm-restart
%{_bindir}/vpm-start
%{_bindir}/vpm-stop
%{_bindir}/vpm-uninstall
%dir %{geminstdir}
%doc %{geminstdir}/Gemfile
%{gemdir}/gems/%{gemname}-%{version}/
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec

%changelog
* Fri Aug 19 2011 Matt Hicks <mhicks@redhat.com> 0.1.0-1
- Initial build
