%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname openshift-sdk
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        OpenShift SDK
Name:           rubygem-%{gemname}
Version:        0.1.5
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

%package -n ruby-%{gemname}
Summary:        OpenShift SDK Ruby Library
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version

%description
This contains the OpenShift Software Development Kit packaged as a rubygem.

%description -n ruby-%{gemname}
This contains the OpenShift Software Development Kit packaged as a ruby site library.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{ruby_sitelib}

# Build and install into the rubygem structure
gem build %{gemname}.gemspec
gem install --local --install-dir %{buildroot}%{gemdir} --force %{gemname}-%{version}.gem

# Symlink into the ruby site library directories
ln -s %{gemdir}/lib/%{gemname}-%{version}/lib/%{gemname} %{buildroot}%{ruby_sitelib}
ln -s %{gemdir}/lib/%{gemname}-%{version}/lib/%{gemname}.rb %{buildroot}%{ruby_sitelib}

# Symlink all the binaries
for binary in `ls %{buildroot}%{gemdir}/bin`
do
  ln -s %{gemdir}/bin/$binary %{buildroot}%{_bindir}/$binary
done

%clean
rm -rf %{buildroot}                                

%files
%defattr(-,root,root,-)
%dir %{geminstdir}
%doc %{geminstdir}/Gemfile
%{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/gems/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec
%{gemdir}/bin/opm
%{gemdir}/bin/opm-add-to-repo
%{gemdir}/bin/opm-build
%{gemdir}/bin/opm-control-to-spec
%{gemdir}/bin/opm-create
%{gemdir}/bin/opm-create-rpm
%{gemdir}/bin/opm-deploy
%{gemdir}/bin/opm-destroy
%{gemdir}/bin/opm-export
%{gemdir}/bin/opm-help
%{gemdir}/bin/opm-inspect
%{gemdir}/bin/opm-inspect-descriptor
%{gemdir}/bin/opm-install
%{gemdir}/bin/opm-list-applications
%{gemdir}/bin/opm-list-available-cartridges
%{gemdir}/bin/opm-list-installed-cartridges
%{gemdir}/bin/opm-restart
%{gemdir}/bin/opm-start
%{gemdir}/bin/opm-stop
%{gemdir}/bin/opm-uninstall

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb
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

%changelog
* Mon Aug 22 2011 Matt Hicks <mhicks@redhat.com> 0.1.5-1
- Supporting library packaging and rubygem packaging (mhicks@redhat.com)
- Merge branch 'master' of github.com:openshift/fata-morgana (ramr@redhat.com)
- remove unneeded require uuid (markllama@redhat.com)
- Bug fixes. (ramr@redhat.com)
- Changing vostok=>openshift (kraman@gmail.com)
- Removing uuid requires from model (kraman@gmail.com)
- Adding Rake 0.9.2 as a development dependency (kraman@gmail.com)
- Fixed paths {vostok => openshift} for test data files Added user model test
  (kraman@gmail.com)
- Moving to state_machine 1.0.1 compatible syntax (mhicks@redhat.com)

* Fri Aug 19 2011 Matt Hicks <mhicks@redhat.com> 0.1.4-1
- Including tests in the gem (mhicks@redhat.com)

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
