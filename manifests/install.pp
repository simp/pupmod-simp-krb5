# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# Install the MIT Kerberos client
#
# @param ensure
#   The package state to ensure
#
#   * Compatible with the ``Package`` Resource ``ensure`` parameter can
#
# @param haveged
#   Include ``haveged`` for entropy generation.
#
# @author Trevor Vauthan <tvaughan@onyxpoint.com>
#
class krb5::install (
  String  $ensure  = 'latest',
  Boolean $haveged = $::krb5::haveged
) {
  assert_private()

  if $haveged {
    include '::haveged'
  }

  package { [
    'krb5-workstation',
    'pam_krb5'
  ]:
    ensure => $ensure
  }

  if $facts['os']['name'] in ['CentOS', 'RedHat', 'OracleLinux'] {
    if $facts['os']['release']['major'] < '7' {
      package { 'krb5-auth-dialog': ensure => $ensure }
    }
  }
}
