# @summary Kerberos 5 management and manipulation
#
# This base class installs everything necessary for basic KRB client use
#
# We modify the default ``/etc/krb5.conf`` to use an include structure under
# ``/etc/krb5.conf.simp.d``. Each ``[subsection]`` is broken out into a
# separate directory and all files in that directory are included.
#
# @param ldap
#   Configure the system to incorporate LDAP components
#
#   * This presently does **not** set up the LDAP back-end for KRB5
#
# @param firewall
#   Use the SIMP iptables module
#
# @param haveged
#   Deprecated; use `rngd` instead. Use the SIMP haveged module to provide
#   entropy. `simp/haveged` is an optional dependency, so the module must be
#   installed separately. This parameter will be removed in the next major
#   release.
#
#   * When unset, this follows `simp_options::haveged` (default `true`),
#     unless `rngd` is `true`, in which case haveged is not used
#   * When `true`, a deprecation warning is emitted
#
# @param rngd
#   Include the SIMP `rngd` class to provide entropy. By default `rngd` only
#   installs `rng-tools`; set `rngd::service_ensure` and `rngd::service_enable`
#   to run the service. When managing a KDC, `rngd` is ordered before the
#   realm initialization.
#
# @param enctypes
#   An Array of default permitted encryption types
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5 (
  Boolean           $ldap     = simplib::lookup('simp_options::ldap', { 'default_value' => false }),
  Boolean           $firewall = simplib::lookup('simp_options::firewall', { 'default_value' => false }),
  Optional[Boolean] $haveged  = undef,
  Boolean           $rngd     = false,
  Array[String]     $enctypes = ['aes256-cts-hmac-sha1-96', 'aes128-cts-hmac-sha1-96']
) {
  simplib::assert_metadata($module_name)

  # Existing sites keep haveged unless they opt in to rngd or turn it off.
  $haveged_enabled = $haveged ? {
    undef   => (!$rngd and simplib::lookup('simp_options::haveged', { 'default_value' => true })),
    default => $haveged,
  }

  if $haveged_enabled {
    deprecation(
      'krb5::haveged',
      "${module_name}: haveged support is deprecated and will be removed in the next major release. Set 'krb5::rngd: true' (and 'krb5::haveged: false') to use 'simp/rngd' instead.",
      false
    )
  }

  contain 'krb5::install'
  contain 'krb5::config'

  Class['krb5::install'] -> Class['krb5::config']
}
