# == Define: krb5::conf::realm
#
# This define allows you to add a realm to the [realms] section of
# /etc/krb5.conf
#
# man 5 krb5.conf -> REALMS SECTION
#
# == Parameters
#
# [*name*]
#   The affected Realm. This will be upcased if not done already.
#
# [*admin_server*]
# [*kdc*]
# [*database_module*]
# [*default_domain*]
# [*v4_instance_convert*]
#   A hash of 'tag name' to 'tag value' mappings for default domain mapping
#   translations.
#
# [*v4_realm*]
# [*auth_to_local_names*]
#   A hash of 'principal names' to 'local user names' per the man page.
#
# [*auth_to_local*]
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
define krb5::conf::realm (
  $admin_server,
  $kdc = '',
  $database_module = '',
  $default_domain = '',
  $v4_instance_convert = '',
  $v4_realm = '',
  $auth_to_local_names = '',
  $auth_to_local = ''
) {

  concat_fragment { "krb5.conf+${name}_realm":
    content => template('krb5/realm.erb')
  }
}
