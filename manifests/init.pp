# Kerberos 5 management and manipulation.
#
# This base class installs everything necessary for basic KRB client use.
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
#   Use the SIMP haveged module
#
# @param enctypes
#   An Array of default permitted encryption types
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5 (
  Boolean       $ldap     = simplib::lookup('simp_options::ldap', { 'default_value' => false }),
  Boolean       $firewall = simplib::lookup('simp_options::firewall', { 'default_value' => false }),
  Boolean       $haveged  = simplib::lookup('simp_options::haveged', { 'default_value' => true }),
  Array[String] $enctypes = [ 'aes256-cts-hmac-sha1-96', 'aes128-cts-hmac-sha1-96' ]
){
  contain '::krb5::install'
  contain '::krb5::config'

  Class['krb5::install'] -> Class['krb5::config']
}
