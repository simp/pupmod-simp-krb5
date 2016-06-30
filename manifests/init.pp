# Kerberos 5 management and manipulation.
#
# This base class installs everything necessary for basic KRB client use.
#
# We modify the default /etc/krb5.conf to use an include structure under
# /etc/krb5.conf.simp.d. Each [subsection] is broken out into a separate
# directory and all files in that directory are included.
#
# @param use_ldap [Boolean] If set, configure the system to incorporate LDAP
#   components.
#   @note This presently does not set up the LDAP back-end for KRB5
# @param use_iptables [Boolean] If set, use the SIMP iptables module.
# @param enctypes [Array(String)] An Array of default permitted encryption
#   types.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5 (
  $use_ldap = pick(getvar('::use_ldap'), hiera('use_ldap', false)),
  $use_iptables = pick(getvar('::use_iptables'), hiera('use_iptables', false)),
  $use_haveged = defined('$::use_haveged') ? { true => getvar('::use_haveged'), default => hiera('use_haveged', true) },
  $enctypes = [ 'aes256-cts-hmac-sha1-96', 'aes128-cts-hmac-sha1-96' ]

){

  validate_bool($use_ldap)
  validate_bool($use_iptables)
  validate_bool($use_haveged)
  validate_array($enctypes)

  contain '::krb5::install'
  contain '::krb5::config'

  Class['krb5::install'] -> Class['krb5::config']
}
