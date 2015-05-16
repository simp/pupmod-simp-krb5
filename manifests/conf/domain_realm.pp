# == Define: krb5::conf::domain_realm
#
# This define allows you to configure individual domain => realm mappings.
#
# It was specifically created so that you could pass in your domains as an
# array and then your realm as a value.
#
# man 5 krb5.conf
#
# == Parameters
#
# [*name*]
#   A unique domain definition.
#
# [*realm*]
#   The realm to which to map your domain.
#
# [*ensure*]
#   Whether to set or clear the key. Valid values are 'present' and 'absent'.
#   Setting anything besides 'absent' will default to 'present'.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
define krb5::conf::domain_realm (
  $realm,
  $ensure = 'present'
) {

  krb5::conf { "domain_realm_$name":
    ensure  => $ensure,
    section => 'domain_realm',
    key     => $name,
    value   => $realm
  }

  validate_array_member($ensure, ['absent','present'])
}
