# == Class krb5::kdc
#
# This class provides the necessary structure to manage the Kerberos 5 KDC on a
# given system.
#
# The variables used here can be found in kdc.conf(5).
#
# Any variable *not* declared here can be managed using the augeas type.
# However, you *must* target $krb5::kdc::kdc_conf_fragdir/defaults.conf as your
# target in augeas!
#
# Also, make sure that your augeas resources notify Concat_build['kdc.conf'].
#
# == Parameters
#
# [*kdc_ports*]
# [*kdc_tcp_ports*]
# [*client_nets*]
#   The client networks allowed to connect to the KDC.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5::kdc (
  $kdc_ports = ['88','750'],
  $kdc_tcp_ports = [],
  $client_nets = hiera('client_nets')
) {

  $l_kdc_ports = join($kdc_ports,',')
  $kdc_conf_fragdir = fragmentdir('kdc.conf')

  augeas { 'krb5_server_kdcdefaults_kdc_ports':
    incl    => "${kdc_conf_fragdir}/defaults.conf",
    lens    => 'Krb5Kdc.lns',
    changes => [ "set kdcdefaults/kdc_ports '${l_kdc_ports}'" ],
    require => [
      Package['krb5-server'],
      Concat_fragment['kdc.conf+defaults.conf'],
      File['/usr/share/augeas/lenses/krb5kdc.aug']
    ],
    notify  => Concat_build['kdc.conf']
  }

  concat_build { 'kdc.conf':
    file_delimiter => "\n\n",
    target         => '/var/kerberos/krb5kdc/kdc.conf',
    require        => Package['krb5-server'],
    notify         => [
      Service['krb5kdc'],
      Service['kadmin']
    ]
  }

  concat_fragment { 'kdc.conf+defaults.conf':
    externally_managed => true
  }

  file { '/var/kerberos/krb5kdc':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    require => Package['krb5-server']
  }

  file { '/var/kerberos/krb5kdc/kdc.conf':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    notify  => Concat_build['kdc.conf']
  }

  file { '/usr/share/augeas/lenses/krb5kdc.aug':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/krb5/krb5kdc.aug'
  }

  if !empty($kdc_tcp_ports) {
    iptables::add_tcp_stateful_listen { 'allow_kdc':
      order       => '11',
      client_nets => $client_nets,
      dports      => $kdc_tcp_ports
    }
  }

  if !empty($kdc_ports) {
    iptables::add_udp_listen { 'allow_kdc':
      order       => '11',
      client_nets => $client_nets,
      dports      => $kdc_ports
    }
  }

  # The ports for kadmind
  iptables::add_udp_listen { 'allow_kadmind':
    order       => '11',
    client_nets => $client_nets,
    dports      => ['464']
  }
  iptables::add_tcp_stateful_listen { 'allow_kadmind':
    order       => '11',
    client_nets => $client_nets,
    dports      => ['464', '749']
  }

  krb5_acl { 'remove_default':
    ensure         => 'absent',
    principal      => '*/admin@EXAMPLE.COM',
    operation_mask => '*'
  }

  package { 'krb5-server':
    ensure => 'latest'
  }

  service { [
      'krb5kdc',
      'kadmin'
    ]:
    ensure     => 'running',
    hasrestart => true,
    hasstatus  => true,
    require    => Package['krb5-server']
  }

  validate_array($kdc_ports)
  validate_array($kdc_tcp_ports)
  validate_net_list($client_nets)
}
