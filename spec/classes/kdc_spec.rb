require 'spec_helper'

shared_examples_for 'common kdc config' do
  # krb5::kdc
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_class('krb5::kdc') }
  it { is_expected.to create_class('krb5::kdc::install')}
  it { is_expected.to create_class('krb5::kdc::config')}
  it { is_expected.to create_class('krb5::kdc::service')}
  it { is_expected.to create_krb5__kdc__realm(facts[:domain])}
  it { is_expected.to create_krb5__setting__realm(facts[:domain])}
  it { is_expected.to contain_class('krb5::kdc::auto_keytabs')}
  it_should_behave_like 'auto_keytab'
  # krb5::kdc::install
  it { is_expected.to contain_package('krb5-server')}
  # krb5::kdc::config
  it { is_expected.to create_file('/var/kerberos/krb5kdc/kdc.conf.simp.d')}
  it { is_expected.to create_file('/var/kerberos/krb5kdc/.princ_db_creds')}
  it { is_expected.to create_file('/var/kerberos/krb5kdc/kdc.conf')}
  it { is_expected.to create_file('/var/kerberos/krb5kdc/kdc.conf.d')}
  it { is_expected.to create_exec('initialize_principal_database')}
  it { is_expected.to create_krb5__setting('kdcdefaults:kdc_ports')}
  it { is_expected.to create_krb5__setting('kdcdefaults:kdc_tcp_ports')}
  it { is_expected.to create_krb5_acl('remove_default')}
  # krb5::kdc::service
  it { is_expected.to create_service('krb5kdc')}
  it { is_expected.to create_service('kadmin')}
end

shared_examples_for 'auto_keytab' do
  it { is_expected.to create_krb5kdc_auto_keytabs('__default__').with(:realms => facts[:domain])}
end

shared_examples_for 'selinux hotfix' do
  it { is_expected.to create_vox_selinux__module('krb5kdc_hotfix') }
end

shared_examples_for 'firewall' do
  it { is_expected.to contain_class('iptables')}
  it { is_expected.to create_iptables__listen__tcp_stateful('allow_kdc')}
  it { is_expected.to create_iptables__listen__udp('allow_kdc')}
  it { is_expected.to create_iptables__listen__udp('allow_kadmind')}
  it { is_expected.to create_iptables__listen__tcp_stateful('allow_kadmind')}
end

describe 'krb5::kdc' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:server_facts] = server_facts_hash unless (Gem::Version.new(Puppet.version) >= Gem::Version.new('5.0.0'))
          facts
        end

        context 'with default parameters' do
          it_should_behave_like 'common kdc config'
          it { is_expected.to contain_class('haveged')}
          it { is_expected.to_not contain_package('krb5-server-ldap')}
          it { is_expected.to_not contain_class('krb5::kdc::firewall')}

          if ['RedHat','CentOS','OracleLinux'].include?(facts[:operatingsystem]) and facts[:operatingsystemmajrelease] > '6'
            it { is_expected.to contain_class('krb5::kdc::selinux_hotfix') }
          else
            it { is_expected.to_not contain_class('krb5::kdc::selinux_hotfix') }
          end
        end

        context 'with firewall = true, haveged = true, ldap = true' do
          let(:params) {{:firewall => true, :haveged => true, :ldap => true}}
          it_should_behave_like 'common kdc config'
          if ['RedHat','CentOS','OracleLinux'].include?(facts[:operatingsystem]) and facts[:operatingsystemmajrelease] > '6'
            it_should_behave_like 'selinux hotfix'
          end
          it { is_expected.to contain_class('haveged')}
          it { is_expected.to contain_package('krb5-server-ldap')}
          it { is_expected.to contain_class('krb5::kdc::firewall')}
          it_should_behave_like 'firewall'
        end

        context 'when including the krb5::client class first' do
          let(:pre_condition) do
            'include krb5::client'
          end

          it_should_behave_like 'common kdc config'

          if ['RedHat','CentOS','OracleLinux'].include?(facts[:operatingsystem]) and facts[:operatingsystemmajrelease] > '6'
            it_should_behave_like 'selinux hotfix'
          end
        end
      end
    end
  end
end
