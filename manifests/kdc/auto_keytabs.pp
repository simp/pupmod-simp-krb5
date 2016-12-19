# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# This class provides a mechanism for auto-generating keytabs on the KDC as
# well as provisioning those keytabs for distribution via Puppet if possible.
#
# The keytabs will be collected in a directory that is, by default, located at
# `/var/kerberos/krb5kdc/generated_keytabs`.
#
# The target directory will have subdirectories created, one per
# `host/fqdn@REALM` principal that match the `fqdn` of the host.
#
# Each of those directories will have a krb5.keytab file created that contains
# *all* discovered keytabs for the principal, *regardless of REALM*.
#
# @note If this is enabled on a Puppet server, and `$introspect` is `true`,
#   it will attempt to install the keytabs into the
#   `${environmentpath}/${environment}/site_files/${module_name}_files/files/keytabs`
#   directory.
#
#   It will also attempt to *automatically* create host keytabs for any hosts
#   in one of the following two directories:
#     * `${environmentpath}/${environment}/keydist`
#     * `${environmentpath}/${environment}/site_files/pki_files/files/keydist`
#
#     @note For any of the above, if `$environmentpath` is empty, or does not
#       exist, then `$confdir` will be substituted for
#       `${environmentpath}/${environment}`
#
# @param introspect [Boolean] If set, attempt to discover, and create all
#   relevant keytabs from data on the Puppet server.
#   @note This has no effect if you aren't running on a Puppet server.
# @param output_dir [Absolute_Path] The directory into which to install the
#   keytabs.
# @param all_known [Boolean] If set, generate keytabs for any 'host/.*' entries
#   known to the KDC.
# @param user [String] The user that should own the keytab files.
# @param group [String] The group that should own the keytab files.
# @param realms [String] The REALMs into which the hosts should be added unless
#   otherwise specified in the `$hosts` Hash. Will be auto-upcased.
# @param global_services [Array(String)] An Array of Kerberos services that
#   should be added to *all* hosts.
# @param hosts [Hash] A Hash of hosts for which keytabs should be
#   generated, and kept in the KDC by Puppet.
#   This is done as a Hash so that you don't end up with thousands of Puppet
#   resources in your catalog.
#   @note The Hash should be formatted as follows:
#     {
#       'fqdn' =>
#         'ensure'   => ('absent'|'present') # Required
#         'realms'   => ['REALM1', 'REALM2'] # Optional. Will be auto upcased.
#         'services' => ['svc1','svc2']      # Optional
#     }
#
#   @note This will be combined with the auto-generated hosts if $auto_generate
#     is `true`
# @param purge [Boolean] If set, purge any keytab directories for systems that
#   we don't know about.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class krb5::kdc::auto_keytabs (
  Boolean                        $introspect      = true,
  Optional[Stdlib::Absolutepath] $output_dir      = undef,
  Boolean                        $all_known       = false,
  String                         $user            = 'root',
  String                         $group           = 'puppet',
  String                         $realms          = simplib::lookup('krb5::kdc::auto_realm', { 'default_value' => $facts['domain'] }),
  Array[String]                  $global_services = [],
  Boolean                        $purge           = true,
  Hash[String,
    Struct[{'ensure'             => Enum['absent','present'],
            Optional['realms']   => Array[String],
            Optional['services'] => Array[String]
    }]
  ]                              $hosts           = {}
) inherits ::krb5::kdc {

  assert_private()

  if empty($output_dir) {
    $_output_dir = '__default__'
  }
  else {
    $_output_dir = $output_dir
  }

  krb5kdc_auto_keytabs { $_output_dir:
    introspect      => $introspect,
    all_known       => $all_known,
    user            => $user,
    group           => $group,
    realms          => $realms,
    global_services => $global_services,
    hosts           => $hosts,
    purge           => $purge
  }
}
