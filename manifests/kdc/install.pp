# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# == Class krb5::kdc::install
#
# Install the krb5kdc packages
#
# @param ensure
#   The package state to ensure
#
#   * Accepts all valid options for the ``Package`` resource's ``ensure``
#     parameter
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5::kdc::install (
  String $ensure = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
) inherits ::krb5::kdc {

  assert_private()

  package { 'krb5-server':
    ensure => $ensure
  }

  if $::krb5::kdc::ldap {
    package { 'krb5-server-ldap':
      ensure => $ensure
    }
  }
}
