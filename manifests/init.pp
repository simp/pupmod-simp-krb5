# == Class: krb5
#
# Kerberos 5 management and manipulation.
#
# This base class installs everything necessary for basic KRB client use.
#
# We modify the default /etc/krb5.conf to use an include structure under
# /etc/krb5.conf.d. Each [subsection] is broken out into a separate directory
# and all files in that directory are included.
#
# This allows the use of multiple 'file' types to ensure a purged configuration
# with no extra cruft lying around. While, at the same time, allowing the use
# of the 'augeas' type where possible.
#
# == Parameters
#
# [*default_realm*]
#   The default realm to which to bind.
#
# [*realm_domains*]
#   Array of domains bound to the default realm set in $default_realm
#
# [*dns_lookup_realm*]
#   Use DNS TXT records to lookup the realm.
#
# [*dns_lookup_kdc*]
#   Use DNS SRV records to lookup the KDC.
#
# [*renew_lifetime*]
#   The default renewable lifetime for initial tickets.
#
# [*forwardable*]
#   Whether or not to make initial tickets forwardable by default. This is
#   needed for SSH GSSAPI.
#
# [*clockskew*]
#   Max allowable amount of clockskew allowed before assuming that a message
#   is invalid.
#
# [*permitted_tgs_enctypes*]
#   Supported encryption types reported by the KDC.
#
# [*permitted_tkt_enctypes*]
#   Permitted client encryption types.
#
# [*permitted_enctypes*]
#   Permitted session key encryption types.
#
# [*puppet_exclusive_managed*]
#   Set to false to allow users to add files to the /etc/krb5.conf.d directory manually.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5 (
  $default_realm = inline_template('<%= @domain.upcase %>'),
  $realm_domains = [ inline_template('.<%= @domain %>'), $::domain ],
  $dns_lookup_realm = false,
  $dns_lookup_kdc = true,
  $renew_lifetime = '7d',
  $forwardable = true,
  $clockskew = '500',
  $permitted_tgs_enctypes = 'aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 aes256-cts aes128-cts des3-cbc-sha1',
  $permitted_tkt_enctypes = 'aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 aes256-cts aes128-cts des3-cbc-sha1',
  $permitted_enctypes = 'aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 aes256-cts aes128-cts des3-cbc-sha1',
  $puppet_exclusive_managed = true
) {

  concat_build { 'krb5.conf':
    file_delimiter => "\n\n",
    target         => '/etc/krb5.conf',
    require        => Package['krb5-workstation']
  }

  # This is a place to dump augeas output that will be pulled into the
  # krb5.conf.
  concat_fragment { 'krb5.conf+00HEADER':
    content =>
"# This file managed by Puppet
# Any changes made will be reverted at the next run\n"
  }

  file { '/usr/share/augeas/lenses/krb5.aug':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/krb5/krb5.aug'
  }

  package { [
    'krb5-auth-dialog',
    'krb5-workstation',
    'pam_krb5'
  ]:
    ensure => 'latest'
  }

  file { '/etc/krb5.conf':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Concat_build['krb5.conf']
  }

  krb5::conf { 'libdefaults_default_realm':
    section => 'libdefaults',
    key     => 'default_realm',
    value   => $default_realm
  }

  krb5::conf { 'libdefaults_dns_lookup_realm':
    section => 'libdefaults',
    key     => 'dns_lookup_realm',
    value   => $dns_lookup_realm
  }

  krb5::conf { 'libdefaults_dns_lookup_kdc':
    section => 'libdefaults',
    key     => 'dns_lookup_kdc',
    value   => $dns_lookup_kdc
  }

  krb5::conf { 'libdefaults_renew_lifetime':
    section => 'libdefaults',
    key     => 'renew_lifetime',
    value   => $renew_lifetime
  }

  krb5::conf { 'libdefaults_forwardable':
    section => 'libdefaults',
    key     => 'forwardable',
    value   => $forwardable
  }

  krb5::conf { 'libdefaults_clockskew':
    section => 'libdefaults',
    key     => 'clockskew',
    value   => $clockskew
  }

  krb5::conf { 'libdefaults_permitted_tgs_enctypes':
    section => 'libdefaults',
    key     => 'permitted_tgs_enctypes',
    value   => $permitted_tgs_enctypes
  }

  krb5::conf { 'libdefaults_permitted_tkt_enctypes':
    section => 'libdefaults',
    key     => 'permitted_tkt_enctypes',
    value   => $permitted_tkt_enctypes
  }

  krb5::conf { 'libdefaults_permitted_enctypes':
    section => 'libdefaults',
    key     => 'permitted_enctypes',
    value   => $permitted_enctypes
  }

  krb5::conf::domain_realm { $realm_domains:
    realm => $default_realm
  }

  validate_bool($dns_lookup_realm)
  validate_bool($dns_lookup_kdc)
  validate_bool($forwardable)
  validate_integer($clockskew)
  validate_bool($puppet_exclusive_managed)
}
