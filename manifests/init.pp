# Kerberos 5 management and manipulation.
#
# This base class installs everything necessary for basic KRB client use.
#
# We modify the default /etc/krb5.conf to use an include structure under
# /etc/krb5.conf.simp.d. Each [subsection] is broken out into a separate
# directory and all files in that directory are included.
#
# @param ldap [Boolean] If set, configure the system to incorporate LDAP
#   components.
#   @note This presently does not set up the LDAP back-end for KRB5
# @param firewall [Boolean] If set, use the SIMP iptables module.
# @param haveged [Boolean] If set, use the SIMP haveged module.
# @param selinux [Boolean] If set, use the SIMP selinux module.
# @param enctypes [Array(String)] An Array of default permitted encryption
#   types.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5 (
  $ldap = simplib::lookup('simp_options::ldap', { 'default_value' => false, 'value_type' => Boolean }),
  $firewall = simplib::lookup('simp_options::firewall', { 'default_value' => false, 'value_type' => Boolean }),
  $haveged = simplib::lookup('simp_options::haveged', { 'default_value' => false, 'value_type' => Boolean }),
  $selinux = simplib::lookup('simp_options::selinux', { 'default_value' => false, 'value_type' => Boolean }),
  $enctypes = [ 'aes256-cts-hmac-sha1-96', 'aes128-cts-hmac-sha1-96' ]
){

  #validate_bool($ldap)
  #validate_bool($firewall)
  #validate_bool($haveged)
  #validate_array($enctypes)

  contain '::krb5::install'
  contain '::krb5::config'

  Class['krb5::install'] -> Class['krb5::config']
}
