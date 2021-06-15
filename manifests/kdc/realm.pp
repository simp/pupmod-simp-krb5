# @summary Allows you to add a realm to the ``[realms]`` section of ``/var/kerberos/krb5kdc/kdc.conf``.
#
# Note: The kdc.conf file is *fully managed* by Puppet
#
# @see kdc.conf(5) -> REALMS SECTION
#
# @attr name  The affected Realm. This will be upcased if not done already.
#
# @param initialize  If set, auto-initialize the Realm. This will
#   add an initial Principal for this Realm.
# @param auto_principal  If ``$initialize`` is set, this principal will
#   be created as an administrative Principal on the Realm.
# @param trusted_nets  networks to allow access into the KDC realm.
# @param acl_file  The path to the KDC realm ACL file.
# @param admin_keytab  The path to the KDC realm keytab.
# @param database_name  The path to the KDC realm database.
# @param default_principal_expiration  The Absolute Time for
#   expiring the principal expiration date for this realm.
#   @see http://web.mit.edu/kerberos/krb5-devel/doc/basic/date_format.html#abstime
# @param default_principal_flags  An array following the
#   format prescribed in the man page. The absence of a '-' in front of the
#   entry implies that a '+' will be added.
# @param dict_file  The path to the dictionary file of strings
#   that are not allowed as passwords.
# @param kadmind_port  The port on which kadmind should listen.
# @param kpasswd_port  The port on which kpasswd should listen.
# @param key_stash_file  The path to the KDC realm master key.
# @param kdc_ports  UDP ports upon which the KDC should listen.
# @param kdc_tcp_ports  TCP ports upon which the KDC should listen.
# @param master_key_name  The principal associated with the master key.
# @param master_key_type  The master key's key type.
# @param max_life  The maximum time period for which a ticket may be valid.
#   Should be a valid krb5 Time Duration string.
#   @see http://web.mit.edu/kerberos/krb5-1.13/doc/basic/date_format.html#duration
# @param max_renewable_life  The maximum time period during which
#   a valid ticket may be renewed.  Should be a valid krb5 Time Duration string.
# @param iprop_enable  Whether incremental database propogation is enabled.
# @param iprop_master_ulogsize  The maximum number of log entries for
#   incremental propogation.
# @param iprop_slave_poll  How often the KDC polls for new updates
#   from the master.
# @param supported_enctypes  The default key/salt combinations for this realm.
# @param reject_bad_transit  Whether to check the list of transited
#   realms for cross-realm tickets.
# @param config_dir  The path to the Puppet managed config files.
# @param ensure  Whether to set or clear the key.
#   Valid values are 'present' and 'absent'. Setting anything besides 'absent'
#   will default to 'present'.
# @param firewall Whether to add appropriate iptables rules for KDC
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
define krb5::kdc::realm (
  Boolean                        $initialize                   = false,
  String                         $auto_principal               = 'puppet_auto',
  Simplib::Netlist               $trusted_nets                 = pick(
                                                                    getvar('krb5::kdc::trusted_nets'),
                                                                    simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1']})
                                                                  ),
  Stdlib::Absolutepath           $acl_file                     = "/var/kerberos/krb5kdc/kadm5_${name}.acl",
  Stdlib::Absolutepath           $admin_keytab                 = "/var/kerberos/krb5kdc/kadm5_${name}.keytab",
  Optional[String]               $database_name                = undef,
  Optional[String]               $default_principal_expiration = undef,
  Array[String]                  $default_principal_flags      = [],
  Stdlib::Absolutepath           $dict_file                    = '/usr/share/dict/words',
  Optional[Simplib::Port]        $kadmind_port                 = undef,
  Optional[Simplib::Port]        $kpasswd_port                 = undef,
  Optional[Stdlib::Absolutepath] $key_stash_file               = undef,
  Array[Simplib::Port]           $kdc_ports                    = [],
  Array[Simplib::Port]           $kdc_tcp_ports                = [],
  Optional[String]               $master_key_name              = undef,
  String                         $master_key_type              = 'aes256-cts',
  Optional[String]               $max_life                     = undef,
  Optional[String]               $max_renewable_life           = undef,
  Optional[Boolean]              $iprop_enable                 = undef,
  Optional[Integer]              $iprop_master_ulogsize        = undef,
  Optional[String]               $iprop_slave_poll             = undef,
  Array[String]                  $supported_enctypes           = [ 'aes256-cts:normal', 'aes128-cts:normal' ],
  Optional[Boolean]              $reject_bad_transit           = undef,
  Stdlib::Absolutepath           $config_dir                   = simplib::lookup('krb5::kdc::config_dir', { 'default_value' => '/var/kerberos/krb5kdc/kdc.conf.simp.d' }),
  String                         $ensure                       = 'present',
  Boolean                        $firewall                     = simplib::lookup('krb5::kdc::firewall', { 'default_value' => false })
) {

  if !defined(Class['krb5::kdc']) {
    fail('You must include krb5::kdc before using krb5::kdc::realm')
  }

  if !empty($default_principal_flags) {
    if is_string($_default_principal_flags) {
      $_default_principal_flags = split($default_principal_flags,'\s+')
    }
    else {
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

      simplib::validate_re_array(
        $_default_principal_flags,
        "^([+-]?(${_possible_principal_flag_check_string}))"
      )
    }
  }
  else {
    $_default_principal_flags = []
  }

  if $max_life { krb5::validate_time_duration($max_life) }
  if $max_renewable_life { krb5::validate_time_duration($max_renewable_life) }

  # Formatted for the output file
  $_kdc_ports = join($kdc_ports,',')
  $_kdc_tcp_ports = join($kdc_tcp_ports,',')
  $_supported_enctypes = join($supported_enctypes,',')

  $_name = krb5::munge_conf_filename($name)

  $_upcase_realm = upcase($name)

  file { $acl_file:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    seltype => 'krb5kdc_conf_t'
  }

  file { "${config_dir}/${_name}__realm":
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    seltype => 'krb5kdc_conf_t',
    content => template("${module_name}/kdc/realm.erb")
  }

  if $firewall {
    if !empty($kdc_tcp_ports) {
      iptables::listen::tcp_stateful { "${name}_allow_kdc":
        order        => 11,
        trusted_nets => $trusted_nets,
        dports       => $kdc_tcp_ports
      }
    }

    if !empty($kdc_ports) {
      iptables::listen::udp { "${name}_allow_kdc":
        order        => 11,
        trusted_nets => $trusted_nets,
        dports       => $kdc_ports
      }
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
