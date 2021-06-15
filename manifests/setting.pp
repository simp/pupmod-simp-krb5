# @summary Allows you to set individual configuration elements in ``/etc/krb5.conf``.
#
# Sections with nested sub-sections or allowed repeated keys have their own
# specialized defines.
#
# @see krb5.conf(5)
#
# @attr name  A string of the format `section:key`. For instance, if
#   you wanted to add to the `libdefaults` section with key
#   `clockskew`, you would call this as follows:
#
#     @example Update the [libdefaults] `clockskew` key
#       krb5::setting { 'libdefaults:clockskew': value => 1000 }
#
# @param value  The number/string/boolean that should be used to set the
#   designated value. This will *not* be processed so make sure that it's
#   what you want to output to the system.
#
# @param target  The target *directory* to which to add setting files.
#
# @param ensure  Whether to set or clear the key. Valid values are
#   'present' and 'absent'.  Setting anything besides 'absent' will default to
#   'present'.
#
# @param filemode  The File mode (per the Puppet File resource) that
#   should be set on the settings files.
#
# @param seltype  The SELinux Type to which to set the file that holds
#   the setting.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define krb5::setting (
  Scalar               $value,
  Stdlib::Absolutepath $target   = pick(getvar('krb5::config::config_dir'), '/etc/krb5.conf.d'),
  String               $ensure   = 'present',
  String               $filemode = '0644',
  String               $seltype  = 'krb5_conf_t'
) {

  if !defined(Class['krb5']) {
    fail('You must include krb5 before using krb5::setting')
  }

  if $name !~ Pattern['^.+:.+$'] {
    fail('$name must match /^.+:.+$/')
  }

  $_name_parts = split($name,':')
  $_section = $_name_parts[0]
  $_key = $_name_parts[1]

  $_name = krb5::munge_conf_filename($name)

  file { "${target}/${_name}__setting":
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => $filemode,
    seltype => $seltype,
    content =>"[${_section}]\n  ${_key} = ${value}\n"
  }

  Class['krb5'] -> Krb5::Setting[$name]
}
