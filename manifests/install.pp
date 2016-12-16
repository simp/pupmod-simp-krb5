# Install the MIT Kerberos client
#
#
# @param ensure [String] The package state to ensure. Accepts 'latest' and
#   'installed'.
#
# @param haveged [Boolean] If true, include haveged for entropy generation.
#
# @author Trevor Vauthan <tvaughan@onyxpoint.com>
#
class krb5::install (
  $haveged = $::krb5::haveged,
  $ensure = 'latest',
){

  validate_array_member($ensure, ['latest', 'installed'])
  #validate_bool($haveged)

  if $haveged {
    include '::haveged'
  }

  if $::operatingsystem in ['CentOS', 'RedHat'] {
    package { [
      'krb5-workstation',
      'pam_krb5'
    ]:
      ensure => $ensure
    }

    if $::operatingsystemmajrelease < '7' {
      package { 'krb5-auth-dialog': ensure => $ensure }
    }
  }
  else {
    fail("Installation on '${::operatingsystem}' not yet supported")
  }
}
