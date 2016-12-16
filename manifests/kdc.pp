# This class provides the necessary structure to manage the Kerberos 5 KDC on a
# given system.
#
# The variables used here can be found in kdc.conf(5).
#
# Any variable *not* covered here can be managed using file resources.
#
# @example Add Your Own Custom Config Snippet
#   class my_krb5kdc {
#     include '::krb5::kdc'
#
#     file { "${::krb5::kdc::config_dir}/my_snippet__custom":
#       content => "My Custom Content"
#     }
#
#     Class['krb5::kdc'] -> Class['my_krb5kdc']
#     Class['my_krb5kdc'] ~> Class['krb5::kdc::service']
#   }
#
# @param trusted_nets [Array(NetworkAddress)] An Array of hostnames or IP
#   addresses that are allowed into this system. Only used by the IPTables
#   settings.
# @param ldap [Boolean] If set, configure the system to incorporate LDAP
#   components.
#   @note This presently does not set up the LDAP back-end for KRB5
# @param firewall [Boolean] If set, use the SIMP iptables module.
# @param haveged [Boolean] If set, enable the HAVEGE daemon for entropy
# @param selinux [Boolean] If set, use te SIMP selinux module.
# @param auto_initialize [Boolean] If set, create a default realm do all
#   necessary work to set up the environment for production.
#   @note This will simply use the system defaults. If you want something other
#     than that, you'll need to call the `::krb5::kdc::realm` define directly.
#
#     If you select this, this *will* automatically initialize your Kerberos
#     database and prepare your system to run.
# @param auto_realm [String] If $auto_initialize is set, then use this string
#   as your default Kerberos Realm.
# @param auto_management_principal [String] If $auto_initialize is set, then
#   use this string as the primary Kerberos principal name for the default Realm.
# @param auto_generate_host_keytabs [Boolean] If set, create keytabs for all
#   hosts that Puppet currently knows about.
#   @note Host Principals are identified by having a 'host/<fqdn>' entry in the
#     list of principals. Any host without one of these entries
#     *will be ignored*.
#
#     This is *not* dependent on `$auto_initialize`! You may want to toggle
#     some of the parameters in the `::krb5::kdc::auto_keytabs` class to tailor
#     the generation.
#
#     This capability expects a `${module_name}_files` module to be present in
#     the environment's module path. It is **not** recommended that you place
#     this module inside of the standard module path. Instead, the containing
#     directory should be added to the `modulepath` directive of your
#     `environment.conf`.
#      @see https://docs.puppet.com/puppet/4.5/reference/config_file_environment.html
#        With the `${module_name}_files` module, you should also have a section in
#        your Puppet auth.conf that looks something like the following and is
#        placed **before** the `path /file` stanza.
#
#     @example auth.conf update
#       # Restrict access to a directory that matches the hostname
#       # Example: /environments/production/krb5_files/files/my.host.name.domain
#
#       path ~ ^/file_(metadata|content)/modules/krb5_files/([^/]+)
#       allow $2
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5::kdc (
  $trusted_nets = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1', '::1'], 'value_type' => Array[String]}),
  $config_dir = '/var/kerberos/krb5kdc/kdc.conf.simp.d',
  $ldap = $::krb5::ldap,
  $firewall = $::krb5::firewall,
  $haveged = $::krb5::haveged,
  $selinux = $::krb5::selinux,
  $auto_initialize = true,
  $auto_realm = $::domain,
  $auto_management_principal = 'puppet_auto',
  $auto_generate_host_keytabs = true
) inherits ::krb5 {

  validate_net_list($trusted_nets)
  #validate_absolute_path($config_dir)
  #validate_bool($ldap)
  #validate_bool($firewall)
  #validate_bool($haveged)
  #validate_bool($auto_initialize)
  #validate_string($auto_realm)
  #validate_string($auto_management_principal)
  #validate_bool($auto_generate_host_keytabs)

  if $haveged { include '::haveged' }

  contain '::krb5::kdc::install'
  contain '::krb5::kdc::config'
  contain '::krb5::kdc::service'

  Class['krb5'] -> Class['krb5::kdc']
  Class['krb5::kdc::install'] ~> Class['krb5::kdc::config']
  Class['krb5::kdc::install'] ~> Class['krb5::kdc::service']
  Class['krb5::kdc::config'] ~> Class['krb5::kdc::service']

  # Hackery for a broken SELinux policy in EL7
  if ($::operatingsystem in ['RedHat','CentOS']) and ($::operatingsystemmajrelease > '6') {
    if $selinux {
      include '::krb5::kdc::selinux_hotfix'
      Class['krb5::kdc::config'] -> Class['krb5::kdc::selinux_hotfix']
    }
  }

  if $auto_initialize {
    ::krb5::kdc::realm { $auto_realm:
      initialize     => $auto_initialize,
      auto_principal => $auto_management_principal
    }

    ::krb5::setting::realm { $auto_realm:
      admin_server => $::fqdn,
      kdc          => $::fqdn
    }

    Class['krb5::kdc::config'] -> Krb5::Kdc::Realm[$auto_realm]
    Krb5::Kdc::Realm[$auto_realm] ~> Class['krb5::kdc::service']

    if $haveged {
      Class['haveged'] -> Krb5::Kdc::Realm[$auto_realm]
    }
  }

  if $auto_generate_host_keytabs {
    include '::krb5::kdc::auto_keytabs'

    Class['krb5::kdc::service'] -> Class['krb5::kdc::auto_keytabs']
  }

  # Ensure that all settings are applied prior to the KDC starting
  #
  # This has to be separated due to the same setting code being used on the
  # server and client.

  Krb5::Setting <| |> ~> Class['krb5::kdc::service']
}
