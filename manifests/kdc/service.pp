# == Class krb5::kdc::service
#
# Manage the KRB5 services
#
# @private
#
# @param ensure [String] May be one of 'running' or 'stopped'.
# @param enable [Boolean] If true, enable the services at boot time.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5::kdc::service (
  $ensure = 'running',
  $enable = true
) {

  assert_private()

  service { [
    'krb5kdc',
    'kadmin'
  ]:
    ensure     => $ensure,
    enable     => $enable,
    hasrestart => true,
    hasstatus  => true
  }
}
