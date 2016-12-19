# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# Default System Settings
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
class krb5::config::default_settings {

  assert_private()

  krb5::setting { 'libdefaults:default_realm':          value => $::krb5::config::default_realm }
  krb5::setting { 'libdefaults:dns_lookup_realm':       value => $::krb5::config::dns_lookup_realm }
  krb5::setting { 'libdefaults:dns_lookup_kdc':         value => $::krb5::config::dns_lookup_kdc }
  krb5::setting { 'libdefaults:renew_lifetime':         value => $::krb5::config::renew_lifetime }
  krb5::setting { 'libdefaults:forwardable':            value => $::krb5::config::forwardable }
  krb5::setting { 'libdefaults:clockskew':              value => $::krb5::config::clockskew }
  krb5::setting { 'libdefaults:permitted_tgs_enctypes': value => join($::krb5::config::permitted_tgs_enctypes, ',') }
  krb5::setting { 'libdefaults:permitted_tkt_enctypes': value => join($::krb5::config::permitted_tkt_enctypes, ',') }
  krb5::setting { 'libdefaults:permitted_enctypes':     value => join($::krb5::config::permitted_enctypes, ',') }

  krb5::setting::domain_realm { $::krb5::config::realm_domains: realm => $::krb5::config::default_realm }
}
