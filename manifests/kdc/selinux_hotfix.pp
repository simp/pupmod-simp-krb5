# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# @summary This class provides a hotfix for a broken SELinux policy in EL7
#
# The OS confinement of this class should be done elsewhere.
#
class krb5::kdc::selinux_hotfix {
  assert_private()

  if $facts['os']['selinux']['current_mode'] and ($facts['os']['selinux']['current_mode'] != 'disabled') {
    simplib::assert_optional_dependency($module_name, 'vox_selinux')

    $_config_dir = $krb5::kdc::config_dir
    $_base_config_dir = inline_template('<%= File.dirname(@_config_dir) %>')

    vox_selinux::module { 'krb5kdc_hotfix':
      ensure     => 'present',
      content_te => epp("${module_name}/selinux/krb5kdc_hotfix.te.epp"),
      builder    => 'simple',
      notify     => Class['krb5::kdc::service']
    }
  }
}
