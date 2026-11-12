# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# @summary Install the MIT Kerberos client
#
# @param packages
#   The list of pakages to install
#
#   * Provided by module data
#
# @param ensure
#   The package state to ensure
#
#   * Compatible with the ``Package`` Resource ``ensure`` parameter can
#
# @param haveged
#   Include ``haveged`` for entropy generation (deprecated).
#
# @param rngd
#   Include ``rngd`` for entropy generation.
#
# @author https://github.com/simp/pupmod-simp-krb5/graphs/contributors
#
class krb5::install (
  Array[String[1]] $packages,
  String[1]        $ensure    = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
  Boolean          $haveged   = $krb5::haveged_enabled,
  Boolean          $rngd      = $krb5::rngd
) {
  assert_private()

  if $haveged {
    simplib::assert_optional_dependency($module_name, 'simp/haveged')

    include 'haveged'
  }

  if $rngd {
    include 'rngd'
  }

  package { $packages:
    ensure => $ensure
  }
}
