# == Define: krb5::kdc::add_realm
#
# This define allows you to add a realm to the [realms] section of
# /var/kerberos/krb5kdc/kdc.conf
#
# man 5 kdc.conf -> REALMS SECTION
#
# == Parameters
#
# [*name*]
#   The affected Realm. This will be upcased if not done already.
#
# [*client_nets*]
# Type: Array of Networks
# Default: $::krb5::kdc::client_nets
#   The networks to allow access to the KDC
#
# [*acl_file*]
# [*admin_keytab*]
# [*database_name*]
# [*default_principal_expiration*]
# [*default_principal_flags*]
#   This can be either a comma separated string or an array following the
#   format prescribed in the man page. The absence of a '-' in front of the
#   entry implies that a '+' should be added.
#
# [*dict_file*]
# [*kadmind_port*]
# [*kpasswd_port*]
# [*key_stash_file*]
# [*kdc_ports*]
#   An array of UDP ports.
#
# [*kdc_tcp_ports*]
#   An array of TCP ports.
#
# [*master_key_name*]
# [*master_key_type*]
# [*max_life*]
# [*max_renewable_life*]
# [*iprop_enable*]
# [*iprop_master_ulogsize*]
# [*iprop_slave_poll*]
# [*supported_enctypes*]
# [*reject_bad_transit*]
# [*ensure*]
#   Whether to set or clear the key. Valid values are 'present' and 'absent'.
#   Setting anything besides 'absent' will default to 'present'.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
define krb5::kdc::realm (
  $client_nets = $::krb5::kdc::client_nets,
  $acl_file = '/var/kerberos/krb5kdc/kadm5.acl',
  $admin_keytab = '/var/kerberos/krb5kdc/kadm5.keytab',
  $database_name = '',
  $default_principal_expiration = '',
  $default_principal_flags = '',
  $dict_file = '/usr/share/dict/words',
  $kadmind_port = '',
  $kpasswd_port = '',
  $key_stash_file = '',
  $kdc_ports = [],
  $kdc_tcp_ports = [],
  $master_key_name = '',
  $master_key_type = 'aes256-cts',
  $max_life = '',
  $max_renewable_life = '',
  $iprop_enable = '',
  $iprop_master_ulogsize = '',
  $iprop_slave_poll = '',
  $supported_enctypes = 'aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal',
  $reject_bad_transit = '',
  $ensure = 'present'
) {

  $l_name = regsubst($name,'/','_')

  if !defined(Concat_fragment["kdc.conf+${l_name}.realm"]) {
    concat_fragment { "kdc.conf+${l_name}.realm":
      externally_managed => true
    }
  }

  file { "${krb5::kdc::kdc_conf_fragdir}/${l_name}.realm":
    content => template('krb5/kdc_realm.conf.erb')
  }

  if !empty($kdc_tcp_ports) {
    iptables::add_tcp_stateful_listen { "${name}_allow_kdc":
      order       => '11',
      client_nets => $client_nets,
      dports      => $kdc_tcp_ports
    }
  }

  if !empty($kdc_ports) {
    iptables::add_udp_listen { "${name}_allow_kdc":
      order       => '11',
      client_nets => $client_nets,
      dports      => $kdc_ports
    }
  }

  validate_net_list($client_nets)
  validate_absolute_path($acl_file)
  validate_absolute_path($admin_keytab)
  validate_array($kdc_ports)
  validate_array($kdc_tcp_ports)
  validate_array_member($ensure, ['absent','present'])
}
