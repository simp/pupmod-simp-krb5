# @summary A client class that will connect with the given KDC
#
# By default, this is set up to connect with the KDC that would be configured
# if you use the default options.
#
# @param realms
#   A Hash of Kerberos Realms that provide a Realm paired with an Admin Server
#   and a KDC
#
#   * If you specify nothing here, then the system will try to set up a client
#     with the Puppet server as the KDC. This will fail if no server is
#     specified.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5::client (
  Hash[
    String,
    Struct[{
      admin_server  => Simplib::Host,
      Optional[kdc] => Simplib::Host
    }]
  ] $realms = {}
) {
  include 'krb5'

  # There's a possibility that the krb5::kdc class has already created the
  # default one and you can only declare one realm with a given name.

  if getvar('krb5::kdc::auto_initialize') and (getvar('krb5::kdc::auto_realm') == $facts['networking']['domain']) {
    $_use_default = false
  }
  else {
    $_use_default = true
  }

  if empty($realms) and $_use_default {
    $_default_kdc = simplib::lookup('simp_options::puppet::server', { 'default_value' => $server_facts ? { undef => undef, default => $server_facts['servername'] }})

    if !$_default_kdc {
      fail('Could not determine an appropriate default KDC, please specify the "$realms" hash manually')
    }

    $_realms = {
      $facts['networking']['domain'] => {
        admin_server => $_default_kdc
      }
    }
  }
  else {
    $_realms = $realms
  }

  $_realms.each |String $realm, Hash $attributes| {
    Resource['krb5::setting::realm'] {
      $realm: * => $attributes
    }
  }
}
