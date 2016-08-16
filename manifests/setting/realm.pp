# This define allows you to add a realm to the [realms] section of
# /etc/krb5.conf
#
# man 5 krb5.conf -> REALMS SECTION
#
# @param name [String] The affected Realm. This will be upcased.
#
# @param admin_server [HostString] The host where the admin server is running.
# @param kdc [HostString] The host where the KDC is running.
# @param default_domain [String] The default domain in which hosts are assumed
#   to be present.
# @param v4_instance_convert [Hash] A hash of 'tag name' to 'tag value'
#   mappings for default domain mapping translations.
# @param v4_realm [String] The v4 realm to be used when talking to legacy
#   systems.
# @param auth_to_local_names [Hash] A hash of 'principal names' to 'local user
#   names' per the man page.
# @param auth_to_local [String] A general rule for mapping to local user names.
#   The following values are allowed:
#     DB:<filename>
#     RULE:<exp>
#     DEFAULT
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define krb5::setting::realm (
  $admin_server,
  $kdc = '',
  $default_domain = '',
  $v4_instance_convert = '',
  $v4_realm = '',
  $auth_to_local_names = '',
  $auth_to_local = '',
  $target = pick(getvar('::krb5::config::config_dir'), '/etc/krb5.conf.d'),
) {

  if !defined(Class['krb5']) {
    fail('You must include ::krb5 before using ::krb5::setting::realm')
  }

  validate_string($admin_server)
  validate_string($default_domain)
  if !empty($v4_instance_convert) { validate_hash($v4_instance_convert) }
  validate_string($v4_realm)
  if !empty($auth_to_local_names) { validate_hash($auth_to_local_names) }
  validate_string($auth_to_local)
  if !empty($auth_to_local) { validate_re($auth_to_local,['^DB:/', '^RULE:', '^DEFAULT$' ]) }
  validate_absolute_path($target)

  validate_net_list($admin_server)

  $_name = munge_krb5_conf_filename($name)

  file { "${target}/${_name}__realm":
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    seltype => 'krb5_conf_t',
    content => template('krb5/realm.erb')
  }

  Class['krb5'] -> Krb5::Setting::Realm[$name]
}
