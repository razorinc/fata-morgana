%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname openshift-sdk
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        OpenShift SDK
Name:           rubygem-%{gemname}
Version:        0.1.3
Release:        1%{?dist}
Group:          Development/Languages
License:        AGPLv3
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       rubygem(activemodel)
Requires:       rubygem(highline)
Requires:       rubygem(json_pure)
Requires:       rubygem(mocha)
Requires:       rubygem(parseconfig)
Requires:       rubygem(sqlite3)
BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%description
This contains the OpenShift Software Development Kit packaged as a rubygem.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
gem build %{gemname}.gemspec
mkdir -p %{buildroot}%{gemdir}
gem install --local --install-dir %{buildroot}%{gemdir} --force %{gemname}-%{version}.gem
mkdir -p %{buildroot}%{_bindir}
mv %{buildroot}%{gemdir}/bin/* %{buildroot}%{_bindir}
rmdir %{buildroot}%{gemdir}/bin

%clean
rm -rf %{buildroot}                                

%files
%defattr(-,root,root,-)
%{_bindir}/opm
%{_bindir}/opm-add-to-repo
%{_bindir}/opm-build
%{_bindir}/opm-control-to-spec
%{_bindir}/opm-create
%{_bindir}/opm-create-rpm
%{_bindir}/opm-deploy
%{_bindir}/opm-destroy
%{_bindir}/opm-export
%{_bindir}/opm-help
%{_bindir}/opm-inspect
%{_bindir}/opm-inspect-descriptor
%{_bindir}/opm-install
%{_bindir}/opm-list-applications
%{_bindir}/opm-list-available-cartridges
%{_bindir}/opm-list-installed-cartridges
%{_bindir}/opm-restart
%{_bindir}/opm-start
%{_bindir}/opm-stop
%{_bindir}/opm-uninstall
%dir %{geminstdir}
%doc %{geminstdir}/Gemfile
%{gemdir}/gems/%{gemname}-%{version}
%{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec

%changelog
* Fri Aug 19 2011 Matt Hicks <mhicks@redhat.com> 0.1.3-1
- Fixing build requires (mhicks@redhat.com)

* Fri Aug 19 2011 Matt Hicks <mhicks@redhat.com> 0.1.2-1
- Fixing gemspec readme (mhicks@redhat.com)

* Fri Aug 19 2011 Matt Hicks <mhicks@redhat.com> 0.1.1-1
- Cleaning up docs and build (mhicks@redhat.com)
- Spec fixes and cleanup (mhicks@redhat.com)
- More packaging work (mhicks@redhat.com)

* Fri Aug 19 2011 Matt Hicks <mhicks@redhat.com> 0.1.0-1
- Initial build
