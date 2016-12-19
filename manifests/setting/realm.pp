# This define allows you to add a realm to the ``[realms]`` section of
# ``/etc/krb5.conf``
#
# @see krb5.conf(5) -> REALMS SECTION
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
  Simplib::Host                 $admin_server,
  Optional[Simplib::Host]       $kdc                 = undef,
  Optional[String]              $default_domain      = undef,
  Hash[String,String]           $v4_instance_convert = {},
  Optional[String]              $v4_realm            = undef,
  Hash[String,String]           $auth_to_local_names = {},
  Optional[String]              $auth_to_local       = undef,
  Stdlib::Absolutepath          $target              = pick(getvar('::krb5::config::config_dir'), '/etc/krb5.conf.d'),
) {

  if !defined(Class['krb5']) {
    fail('You must include ::krb5 before using ::krb5::setting::realm')
  }

  $_name = munge_krb5_conf_filename($name)

  file { "${target}/${_name}__realm":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    seltype => 'krb5_conf_t',
    content => template('krb5/realm.erb')
  }

  Class['krb5'] -> Krb5::Setting::Realm[$name]
}
