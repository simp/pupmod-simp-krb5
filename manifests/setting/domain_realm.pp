# This define allows you to configure individual domain => realm mappings.
#
# It was specifically created so that you could pass in your domains as a name
# array and then your realm as a value.
#
# man 5 krb5.conf
#
# @param name [String] A unique domain definition.
# @param ensure [String] Whether to set or clear the key. Valid values are
#   'present' and 'absent'.  Setting anything besides 'absent' will default to
#   'present'.
# @param realm [String] The realm to which to map your domain.
# @param target [AbsolutePath] The target *directory* to which to add setting files.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define krb5::setting::domain_realm (
  $realm,
  $ensure = 'present',
  $target = pick(getvar('::krb5::config::config_dir'), '/etc/krb5.conf.d'),
) {

  if !defined(Class['krb5']) {
    fail('You must include ::krb5 before using ::krb5::setting::domain_realm')
  }

  validate_string($realm)
  validate_absolute_path($target)
  validate_array_member($ensure, ['absent','present'])

  krb5::setting { "domain_realm:${name}":
    ensure => $ensure,
    value  => $realm,
    target => $target
  }

  Class['krb5'] -> Krb5::Setting::Domain_realm[$name]
}
