# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# @summary Set up the firewall for the KDC
#
# @param kdc_ports
#   The ``UDP`` ports on which the KDC should listen
#
# @param kdc_tcp_ports
#   The ``TCP`` ports on which the KDC should listen
#
# @param trusted_nets
#   Hostnames and/or IP addresses that are allowed into this system
#
#   * Only used by the IPTables settings
#
# @param allow_kadmind
#   Allow remote connections to ``kadmind``
#
#   * You should probably always allow this
#
# @param kadmind_udp_ports
#   The ``UDP`` ports on which kadmind should listen
#
# @param kadmind_tcp_ports
#   The ``TCP`` ports on which kadmind should listen
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5::kdc::firewall (
  Array[Simplib::Port] $kdc_ports         = $krb5::kdc::config::kdc_ports,
  Array[Simplib::Port] $kdc_tcp_ports     = $krb5::kdc::config::kdc_tcp_ports,
  Simplib::Netlist     $trusted_nets      = $krb5::kdc::config::_trusted_nets,
  Boolean              $allow_kadmind     = true,
  Array[Simplib::Port] $kadmind_udp_ports = [464],
  Array[Simplib::Port] $kadmind_tcp_ports = [464, 749]
) {

  assert_private()

  simplib::assert_optional_dependency($module_name, 'simp/iptables')

  include 'iptables'

  if !empty($kdc_tcp_ports) {
    iptables::listen::tcp_stateful { 'allow_kdc':
      order        => 11,
      trusted_nets => $trusted_nets,
      dports       => $kdc_tcp_ports
    }
  }

  if !empty($kdc_ports) {
    iptables::listen::udp { 'allow_kdc':
      order        => 11,
      trusted_nets => $trusted_nets,
      dports       => $kdc_ports
    }
  }

  if $allow_kadmind {
    # The ports for kadmind
    iptables::listen::udp { 'allow_kadmind':
      order        => 11,
      trusted_nets => $trusted_nets,
      dports       => $kadmind_udp_ports
    }

    iptables::listen::tcp_stateful { 'allow_kadmind':
      order        => 11,
      trusted_nets => $trusted_nets,
      dports       => $kadmind_tcp_ports
    }
  }
}
