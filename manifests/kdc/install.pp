# == Class krb5::kdc::install
#
# Install the krb5kdc packages
#
# @private
#
# @param ensure [String] May be one of 'latest', 'absent', or 'present'.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5::kdc::install (
  $ensure = 'latest'
) inherits ::krb5::kdc {

  assert_private()

  validate_array_member($ensure, ['latest','absent','present'])

  package { 'krb5-server': ensure => $ensure }

  if $::krb5::kdc::ldap {
    package { 'krb5-server-ldap': ensure => $ensure }
  }
}
