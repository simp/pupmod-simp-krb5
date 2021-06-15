# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# @summary Provides the necessary structure to manage the Kerberos 5 KDC on a given system.
#
# The variables used here can be found in kdc.conf(5).
#
# Any variable *not* covered here can be managed using file resources.
#
# @example Add Your Own Custom Config Snippet
#   class my_krb5kdc {
#     include 'krb5::kdc'
#
#     file { "${krb5::kdc::config_dir}/my_snippet__custom":
#       content => "My Custom Content"
#     }
#
#     Class['krb5::kdc'] -> Class['my_krb5kdc']
#     Class['my_krb5kdc'] ~> Class['krb5::kdc::service']
#   }
#
# @param kdb5_password
#   The password that should be used for auto-initializing the Principal
#   database
#
#   * If this password is changed, there will be **no** effect unless the
#     password file is physically removed from the system
#
#   @note For safety, the Principal database will *not* be rebuilt unless it is
#     physically absent from the system
#
# @param kdc_ports
#   The ``UDP`` ports on which the KDC should listen
#
# @param kdc_tcp_ports
#   The ``TCP`` ports on which the KDC should listen
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5::kdc::config (
  String               $kdb5_password = simplib::passgen('kdb5kdc', { 'length' => 1024 }),
  Array[Simplib::Port] $kdc_ports     = [88, 750],
  Array[Simplib::Port] $kdc_tcp_ports = [88, 750]
) inherits krb5::kdc {

  assert_private()

  $_trusted_nets = getvar('krb5::kdc::trusted_nets')
  $_config_dir = getvar('krb5::kdc::config_dir')
  $_firewall = getvar('krb5::kdc::firewall')

  $_kdc_ports = join($kdc_ports,',')
  $_kdc_tcp_ports = join($kdc_tcp_ports,',')
  $_base_config_dir = inline_template('<%= File.dirname(@config_dir) %>')
  $_kdb5_credential_file = "${_base_config_dir}/.princ_db_creds"

  if $_firewall { include 'krb5::kdc::firewall' }

  file { $_config_dir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    recurse => true,
    purge   => true,
    require => Package['krb5-server']
  }

  file { $_kdb5_credential_file:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    replace => false,
    content => $kdb5_password
  }

  file { "${_base_config_dir}/kdc.conf":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => "# This file managed by Puppet
# Any changes made will be reverted at the next run
# If you wish to `enhance` the Puppet managed settings, add your settings to
# ${_base_config_dir}/kdc.conf.d.
#
# Please be aware though, that the last item in the includedir list below will
# be authoritative for any given option.

includedir ${_base_config_dir}/kdc.conf.d
includedir ${_config_dir}\n"
  }

  file { "${_base_config_dir}/kdc.conf.d":
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0600'
  }

  exec { 'initialize_principal_database':
    command => "cat ${_kdb5_credential_file} | kdb5_util create -s -P -",
    creates => "${_base_config_dir}/principal",
    require => File[$_kdb5_credential_file],
    path    => ['/sbin','/bin','/usr/sbin','/usr/bin']
  }

  # The initialization of the principal DB must happen after *all* of the
  # global settings have been properly configured.

  Krb5::Setting <| |> ~> Exec['initialize_principal_database']

  if !empty($kdc_ports) {
    krb5::setting { 'kdcdefaults:kdc_ports':
      value    => $_kdc_ports,
      target   => $_config_dir,
      filemode => '0600',
      seltype  => 'krb5kdc_conf_t'
    }
  }

  if !empty($kdc_tcp_ports) {
    krb5::setting { 'kdcdefaults:kdc_tcp_ports':
      value    => $_kdc_tcp_ports,
      target   => $_config_dir,
      filemode => '0600',
      seltype  => 'krb5kdc_conf_t'
    }
  }

  krb5_acl { 'remove_default':
    ensure         => 'absent',
    principal      => '*/admin@EXAMPLE.COM',
    operation_mask => '*'
  }
}
