# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# This class provides a hotfix for a broken SELinux policy in EL7.
# The OS confinement of this class should be done elsewhere.
#
class krb5::kdc::selinux_hotfix {
  assert_private()

  if $facts['selinux_current_mode'] and ($facts['selinux_current_mode'] != 'disabled') {
    $_config_dir = $::krb5::kdc::config_dir
    $_base_config_dir = inline_template('<%= File.dirname(@_config_dir) %>')

    ensure_resource('package', ['checkpolicy', 'policycoreutils-python'])

    Package['checkpolicy'] -> File["${_base_config_dir}/.selinux"]
    Package['policycoreutils-python'] -> File["${_base_config_dir}/.selinux"]

    file { "${_base_config_dir}/.selinux":
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0600'
    }

    file { "${_base_config_dir}/.selinux/krb5kdc_hotfix.te":
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => template("${module_name}/selinux/krb5kdc_hotfix.te.erb")
    }

    exec { 'krb5kdc_selinux_hotfix_build_module':
      command => '/bin/checkmodule -M -m -o krb5kdc_hotfix.mod krb5kdc_hotfix.te',
      cwd     => "${_base_config_dir}/.selinux",
      unless  => '/sbin/semodule -l | /bin/grep -q krb5kdc_hotfix',
      require => File["${_base_config_dir}/.selinux/krb5kdc_hotfix.te"],
      notify  => Exec['krb5kdc_selinux_hotfix_package_module']
    }

    exec { 'krb5kdc_selinux_hotfix_package_module':
      command     => '/usr/bin/semodule_package -o krb5kdc_hotfix.pp -m krb5kdc_hotfix.mod',
      cwd         => "${_base_config_dir}/.selinux",
      refreshonly => true,
      notify      => Exec['krb5kdc_selinux_hotfix_install_module']
    }

    exec { 'krb5kdc_selinux_hotfix_install_module':
      command     => '/usr/sbin/semodule -i krb5kdc_hotfix.pp',
      cwd         => "${_base_config_dir}/.selinux",
      refreshonly => true,
      notify      => Class['krb5::kdc::service']
    }
  }
}
