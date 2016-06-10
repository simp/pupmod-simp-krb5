# This define allows you to add a realm to the [realms] section of
# /var/kerberos/krb5kdc/kdc.conf
#
# Note: The kdc.conf file is *fully managed* by Puppet
#
# @see man 5 kdc.conf -> REALMS SECTION
#
# @param initialize [Boolean] If set, auto-initialize the Realm. This will
#   add an initial Principal for this Realm.
# @param auto_principal [String] If $initialize is set, this principal will be
#   created as an administrative Principal on the Realm.
# @param name [String] The affected Realm. This will be upcased if not done already.
# @param client_nets [Array] The networks to allow access into the KDC realm.
# @param acl_file [AbsolutePath] The path to the KDC realm ACL file.
# @param admin_keytab [AbsolutePath] The path to the KDC realm keytab.
# @param database_name [AbsolutePath] The path to the KDC realm database.
# @param default_principal_expiration [AbsoluteTime] The Absolute Time for
#   expiring the principal expiration date for this realm.
#   @see http://web.mit.edu/kerberos/krb5-devel/doc/basic/date_format.html#abstime
# @param default_principal_flags [Array(String)] An array following the
#   format prescribed in the man page. The absence of a '-' in front of the
#   entry implies that a '+' will be added.
# @param dict_file [AbsolutePath] The path to the dictionary file of strings
#   that are not allowed as passwords.
# @param kadmind_port [Port] The port on which kadmind should listen.
# @param kpasswd_port [Port] The port on which kpasswd should listen.
# @param key_stash_file [AbsolutePath] The path to the KDC realm master key.
# @param kdc_ports [Array] UDP ports upon which the KDC should listen.
# @param kdc_tcp_ports [Array] TCP ports upon which the KDC should listen.
# @param master_key_name [String] The principal associated with the master key.
# @param master_key_type [String] The master key's key type.
# @param max_life [TimeDuration] The maximum time period for which a ticket may be valid.
# @param max_renewable_life [TimeDuration] The maximum time period during which
#   a valid ticket may be renewed.
# @param iprop_enable [Boolean] Whether incremental database propogation is enabled.
# @param iprop_master_ulogsize [Integer] The maximum number of log entries for
#   incremental propogation.
# @param iprop_slave_poll [DeltaTime] How often the KDC polls for new updates
#   from the master.
# @param supported_enctypes [Array] The default key/salt combinations for this realm.
# @param reject_bad_transit [Boolean] Whether to check the list of transited
#   realms for cross-realm tickets.
# @param ensure [String] Whether to set or clear the key.
#   Valid values are 'present' and 'absent'. Setting anything besides 'absent'
#   will default to 'present'.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
define krb5::kdc::realm (
  $initialize = false,
  $auto_principal = 'puppet_auto',
  $client_nets = pick(
    getvar('::krb5::kdc::client_nets'),
    getvar('::client_nets'),
    hiera('client_nets', ['127.0.0.1'])
  ),
  $acl_file = "/var/kerberos/krb5kdc/kadm5_${name}.acl",
  $admin_keytab = "/var/kerberos/krb5kdc/kadm5_${name}.keytab",
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
  $supported_enctypes = [ 'aes256-cts:normal', 'aes128-cts:normal' ],
  $reject_bad_transit = '',
  $config_dir = pick(getvar('::krb5::kdc::config_dir'), '/var/kerberos/krb5kdc/kdc.conf.simp.d'),
  $ensure = 'present'
) {

  if !defined(Class['krb5::kdc']) {
    fail('You must include ::krb5::kdc before using ::krb5::kdc::realm')
  }

  validate_bool($initialize)
  validate_string($auto_principal)
  validate_net_list($client_nets)
  validate_absolute_path($acl_file)
  validate_absolute_path($admin_keytab)
  if !empty($database_name) { validate_absolute_path($database_name) }
  validate_string($default_principal_expiration)
  if !empty($default_principal_flags) {
    if is_string($_default_principal_flags) {
      $_default_principal_flags = split($default_principal_flags,'\s+')
    }
    else {
      validate_array($default_principal_flags)
      $_default_principal_flags = $default_principal_flags

      $_possible_principal_flags = [
        'allow-tickets',
        'dup-skey',
        'forwardable',
        'hwauth',
        'no-auth-data-required',
        'ok-as-delegate',
        'ok-to-auth-as-delegate',
        'postdateable',
        'preauth',
        'proxiable',
        'pwchange',
        'pwservice',
        'renewable',
        'service',
        'tgt-based'
      ]

      $_possible_principal_flag_check_string = join($_possible_principal_flags, '|')

      validate_re_array(
        $_default_principal_flags,
        "^([+-]?(${_possible_principal_flag_check_string}))"
      )
    }
  }
  else {
    $_default_principal_flags = ''
  }

  validate_port($kdc_ports)
  validate_string($master_key_name)
  validate_string($master_key_type)
  if !empty($max_life) { validate_krb5_time_duration($max_life) }
  if !empty($max_renewable_life) { validate_krb5_time_duration($max_renewable_life) }
  validate_port($kdc_tcp_ports)
  validate_array_member($ensure, ['absent','present'])
  if !empty($iprop_enable) { validate_bool($iprop_enable) }
  if !empty($iprop_master_ulogsize) { validate_integer($iprop_master_ulogsize) }
  validate_string($iprop_slave_poll)
  if !empty($supported_enctypes) { validate_array($supported_enctypes) }
  if !empty($reject_bad_transit) { validate_bool($reject_bad_transit) }

  # Formatted for the output file
  $_kdc_ports = join($kdc_ports,',')
  $_kdc_tcp_ports = join($kdc_tcp_ports,',')
  $_supported_enctypes = join($supported_enctypes,',')

  $_name = munge_krb5_conf_filename($name)

  $_upcase_realm = upcase($name)

  file { $acl_file:
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0600'
  }

  file { "${config_dir}/${_name}__realm":
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template("${module_name}/kdc/realm.erb")
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

  if $initialize {
    krb5_acl { "${name}_puppet_auto_admin":
      target         => $acl_file,
      principal      => "${auto_principal}/admin@${_upcase_realm}",
      operation_mask => '*'
    }

    exec { "add_admin_principal_${auto_principal}":
      command => "kadmin.local -q 'addprinc -randkey ${auto_principal}/admin@${_upcase_realm}'",
      unless  => "kadmin.local -q 'get_principal ${auto_principal}/admin' 2>&1 | \
                  grep -q 'Principal: ${auto_principal}/admin'",
      path    => ['/sbin','/bin','/usr/sbin','/usr/bin']
    }

    exec { "create_admin_principal_${auto_principal}_keytab":
      command => "kadmin.local -q 'ktadd -k ${admin_keytab} ${auto_principal}/admin@${_upcase_realm}'",
      unless  => "echo -e 'read_kt ${admin_keytab}\nlist' | ktutil | grep -q '${auto_principal}/admin@${_upcase_realm}'",
      path    => ['/sbin','/bin','/usr/sbin','/usr/bin'],
      require => Exec["add_admin_principal_${auto_principal}"]
    }
  }
}
