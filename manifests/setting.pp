# == Define: krb5::setting
#
# This define allows you to set individual configuration elements in
# /etc/krb5.conf without explicitly needing to specify all of the augeas
# parameters.
#
# Sections with nested sub-sections or allowed repeated keys have their own
# specialized defines.
#
# For particular configuration parameters, please see:
#
# man 5 krb5.conf
#
# @param name [String] A string of the format `section:key`. For instance, if
#   you wanted to add to the `libdefaults` section with key
#   `clockskew`, you would call this as follows:
#
#     @example Update the [libdefaults] `clockskew` key
#       krb5::setting { 'libdefaults:clockskew': value => '1000' }
#
# @param value [String] The string that should be used to set the desinated
#   value. This string will *not* be processed so make sure that it's what you
#   want to output to the system.
#
# @param target [AbsolutePath] The target *directory* to which to add setting files.
#
# @param ensure [String] Whether to set or clear the key. Valid values are
#   'present' and 'absent'.  Setting anything besides 'absent' will default to
#   'present'.
#
# @param filemode [FileMode] The File mode (per the Puppet File resource) that
#   should be set on the settings files.
#
# @param seltype [String] The SELinux Type to which to set the file that holds
#   the setting.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define krb5::setting (
  $value,
  $target  = pick(getvar('::krb5::config::config_dir'), '/etc/krb5.conf.d'),
  $ensure  = 'present',
  $filemode    = '0644',
  $seltype = 'krb5_conf_t'
) {

  if !defined(Class['krb5']) {
    fail('You must include ::krb5 before using ::krb5::setting')
  }

  #validate_re($name,'^.+:.+$')
  #validate_absolute_path($target)

  $_name_parts = split($name,':')
  $_section = $_name_parts[0]
  $_key = $_name_parts[1]

  $_name = munge_krb5_conf_filename($name)


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
