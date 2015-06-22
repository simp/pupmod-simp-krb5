# == Class: krb5::keytab
#
# A class to distribute Kerberos keytabs in a sane manner.
#
# Users should feel free to do what they like, but this will be consistent.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5::keytab {

  file { '/etc/krb5_keytabs':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    tag     => 'firstrun',
    source  => 'puppet:///modules/pki/keydist/keytabs',
    recurse => true
  }

  file { '/etc/krb5.keytab':
    ensure => 'symlink',
    target => "/etc/krb5_keytabs/${::fqdn}.keytab"
  }
}
