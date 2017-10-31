# This define allows you to add a realm to the ``[realms]`` section of
# ``/etc/krb5.conf``
#
# @see krb5.conf(5) -> REALMS SECTION
#
# @attr name  The affected Realm. This will be upcased.
#
# @param admin_server  The host where the admin server is running.
# @param kdc  The host where the KDC is running.
# @param default_domain  The default domain in which hosts are assumed
#   to be present.
# @param v4_instance_convert  A hash of 'tag name' to 'tag value'
#   mappings for default domain mapping translations.
# @param v4_realm  The v4 realm to be used when talking to legacy
#   systems.
# @param auth_to_local_names  A hash of 'principal names' to 'local user
#   names' per the man page.
# @param auth_to_local  A general rule for mapping to local user names.
#   The following values are allowed:
#     DB:<filename>
#     RULE:<exp>
#     DEFAULT
# @param target  The path to the Puppet managed config files.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define krb5::setting::realm (
  Simplib::Host           $admin_server,
  Optional[Simplib::Host] $kdc                 = undef,
  Optional[String]        $default_domain      = undef,
  Hash[String,String]     $v4_instance_convert = {},
  Optional[String]        $v4_realm            = undef,
  Hash[String,String]     $auth_to_local_names = {},
  Optional[String]        $auth_to_local       = undef,
  Stdlib::Absolutepath    $target              = pick(getvar('::krb5::config::config_dir'), '/etc/krb5.conf.d'),
  String                  $owner               = 'root',
  String                  $group               = 'root',
  String                  $mode                = '0644'
) {

  if !defined(Class['krb5']) {
    fail('You must include ::krb5 before using ::krb5::setting::realm')
  }

  $_name = krb5::munge_conf_filename($name)

  file { "${target}/${_name}__realm":
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    seltype => 'krb5_conf_t',
    content => template("${module_name}/realm.erb")
  }

  Class['krb5'] -> Krb5::Setting::Realm[$name]
}
