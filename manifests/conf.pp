# == Define: krb5::conf
#
# This define allows you to set individual configuration elements in
# /etc/krb5.conf without explicitly needing to specify all of the augeas
# parameters.
#
# Sections with nested sub-sections or allowed repeated keys have their own
# specialized defines.
#
# The [login] section is not supported since we don't support using
# non-ssh-based applications between systems.
#
# If you wish to simply use the augeas type, that is perfectly valid!
#
# For particular configuration parameters, please see:
#
# man 5 krb5.conf
#
# == Parameters
#
# [*section*]
#   The [section] that you wish to manipulate. Valid values are
#   'libdefaults', 'domain_realm', 'dbdefaults', and 'dbmodules'
#
# [*key*]
#   The actual key value that you wish to change under $section.
#
# [*value*]
#   The value to which $key should be set under $section.
#
# [*ensure*]
#   Whether to set or clear the key. Valid values are 'present' and 'absent'.
#   Setting anything besides 'absent' will default to 'present'.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
define krb5::conf (
  $section,
  $key,
  $value,
  $ensure = 'present'
) {

  if $ensure == 'absent' {
    $l_action = 'rm'
  }
  else {
    $l_action = 'set'
  }

  # Yes, this is hackish, but it's actually used properly in this case.
  if !defined(Concat_fragment["krb5.conf+augeas_${section}"]) {
    concat_fragment { "krb5.conf+augeas_${section}":
      externally_managed => true
    }
  }

  $krb_conf_fragdir = fragmentdir('krb5.conf')

  augeas { "krb5_${l_action}_${section}_${key}":
    incl    => "${krb_conf_fragdir}/augeas_${section}",
    lens    => 'Krb5.lns',
    changes => [ "${l_action} ${section}/${key} '${value}'" ],
    require => [
      Package['krb5-workstation'],
      Concat_fragment["krb5.conf+augeas_${section}"],
      File['/usr/share/augeas/lenses/krb5.aug']
    ],
    notify  => Concat_build['krb5.conf']
  }

  validate_array_member($section, ['libdefaults','domain_realm','dbdefaults','dbmodules'])
  validate_array_member($ensure, ['absent','present'])
}
