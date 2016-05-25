# Basic configuration of the MIT Kerberos client
#
# @private
#
# @param config_dir [AbsolutePath] The path to the Puppet managed config files.
# @param default_realm [String] Default realm to which to bind.
# @param realm_domains [Array] Array of domains bound to the default realm set
#   in $default_realm.
# @param dns_lookup_realm [Boolean] Use DNS TXT records to lookup the realm.
# @param dns_lookup_kdc [Boolean] Use DNS SRV records to lookup the KDC.
# @param renew_lifetime [String] The default renewable lifetime for initial
#   tickets. Should be a valid krb5 Time Duration string.
#   @see http://web.mit.edu/kerberos/krb5-1.13/doc/basic/date_format.html#duration
# @parm forwardable [Boolean] Whether or not to make initial tickets
#   forwardable by default. This is needed for SSH GSSAPI.
# @param clockskew [String] Max allowable amount of clockskew allowed before
#   assuming that a message is invalid. Should be a valid krb5 Time Duration
#   string.
#   @see http://web.mit.edu/kerberos/krb5-1.13/doc/basic/date_format.html#duration
# @permitted_tgs_enctypes [Array]
#   Supported encryption types reported by the KDC.
# @permitted_tkt_enctypes [Array] Permitted client encryption types.
# @permitted_enctypes [Array] Permitted session key encryption types.
# @puppet_exclusive_managed [Boolean] Set to false to allow users to add files
#   to the /etc/krb5.conf.d directory manually.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
class krb5::config (
  $config_dir               = '/etc/krb5.conf.simp.d',
  $default_realm            = inline_template('<%= @domain.upcase %>'),
  $realm_domains            = [ inline_template('.<%= @domain %>'), $::domain ],
  $dns_lookup_realm         = false,
  $dns_lookup_kdc           = true,
  $renew_lifetime           = '7d',
  $forwardable              = true,
  $clockskew                = '500',
  $permitted_tgs_enctypes   = $::krb5::enctypes,
  $permitted_tkt_enctypes   = $::krb5::enctypes,
  $permitted_enctypes       = $::krb5::enctypes,
  $puppet_exclusive_managed = true
) inherits ::krb5 {

  assert_private()

  validate_absolute_path($config_dir)
  validate_string($default_realm)
  validate_array($realm_domains)
  validate_bool($dns_lookup_realm)
  validate_bool($dns_lookup_kdc)
  validate_krb5_time_duration($renew_lifetime)
  validate_bool($forwardable)
  validate_krb5_time_duration($clockskew)
  validate_bool($puppet_exclusive_managed)

  $_base_config_dir = inline_template('<%= File.dirname(@config_dir) %>')

  include '::krb5::config::default_settings'

  # Include Directories
  file { '/etc/krb5.conf.d':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    before => File['/etc/krb5.conf']
  }

  file { '/etc/krb5.conf.simp.d':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    purge   => true,
    recurse => true,
    before  => File['/etc/krb5.conf']
  }

  file { '/etc/krb5.conf':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "# This file managed by Puppet
# Any changes made will be reverted at the next run
# If you wish to `enhance` the Puppet managed settings, add your settings to
# /etc/krb5.conf.d.
#
# Please be aware though, that the last item in the includedir list below will
# be authoritative for any given option.

includedir ${_base_config_dir}/krb5.conf.d
includedir ${config_dir}\n"
  }
}
