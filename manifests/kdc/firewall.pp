# Set up the firewall for the KDC
#
# @private
#
#
# @param kdc_ports [Array(Ports)] The UDP ports on which the KDC should listen.
# @param kdc_tcp_ports [Array(Ports)] The TCP ports on which the KDC should listen.
# @param trusted_nets [Array(NetworkAddress)] An Array of hostnames or IP
#   addresses that are allowed into this system. Only used by the IPTables
#   settings.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5::kdc::firewall {

  $kdc_ports = $::krb5::kdc::config::kdc_ports
  $kdc_tcp_ports = $::krb5::kdc::config::kdc_tcp_ports
  $trusted_nets = $::krb5::kdc::config::_trusted_nets

  assert_private()

  validate_port($kdc_ports)
  validate_port($kdc_tcp_ports)
  validate_net_list($trusted_nets)

  include '::iptables'

  if !empty($kdc_tcp_ports) {
    ::iptables::add_tcp_stateful_listen { 'allow_kdc':
      order        => '11',
      trusted_nets => $trusted_nets,
      dports       => $kdc_tcp_ports
    }
  }

  if !empty($kdc_ports) {
    ::iptables::add_udp_listen { 'allow_kdc':
      order        => '11',
      trusted_nets => $trusted_nets,
      dports       => $kdc_ports
    }
  }

  # The ports for kadmind
  ::iptables::add_udp_listen { 'allow_kadmind':
    order        => '11',
    trusted_nets => $trusted_nets,
    dports       => ['464']
  }

  ::iptables::add_tcp_stateful_listen { 'allow_kadmind':
    order        => '11',
    trusted_nets => $trusted_nets,
    dports       => ['464', '749']
  }
}
