Summary: Kerberos 5 (MIT) Puppet Module
Name: pupmod-krb5
Version: 4.1.0
Release: 3
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: puppet >= 3.3.0
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-krb5-test

Prefix:"/etc/puppet/environments/simp/modules"

%description
This puppet module provides the ability to manage MIT Kerberos client and
server configurations.

NOTE: given the highly sensitive nature of Kerberos passwords and tokens, this
module DOES NOT store or use any passwords related to the Kerberos KDC.

This means that you must run '/usr/sbin/kdb5_util create -s' on the KDC to set
the principal adminstrator password and initialize the database.

It is also up to you to register your systems/services with the KDC.

If you forget your password, Puppet can't help you.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/krb5

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/krb5
done

mkdir -p %{buildroot}/usr/share/simp/tests/modules/krb5

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/krb5

%files
%defattr(0640,root,puppet,0750)
/etc/puppet/environments/simp/modules/krb5

%post

%postun
# Post uninstall stuff

%changelog
* Fri Jan 16 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-3
- Changed puppet-server requirement to puppet

* Mon May 19 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-2
- Removed all stock classes so they can be ported to the SIMP module.

* Mon Apr 21 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-1
- Updated to avoid globals and call Hiera instead.

* Sat Mar 01 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-0
- Refactored to pass all lint tests.
- Added rspec tests for test coverage.

* Mon Oct 14 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 0.0.1-3
- Updated the custom types to no longer use Puppet::Util::FileLocking
  since it has been removed.

* Mon Oct 07 2013 Nick Markowski <nmarkowski@keywcorp.com> - 0.0.1-2
- Updated template to reference instance variables with @

* Mon Jan 28 2013 Maintenance - 0.0.1-1
- Create a Cucumber test that includes krb5 in the manifest and runs puppet successfully.

* Mon Sep 10 2012 Maintenance - 0.0.1-0
- Initial implementation of krb5 module.
