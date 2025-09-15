# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'common kdc config' do
  # krb5::kdc
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_class('krb5::kdc') }
  it { is_expected.to create_class('krb5::kdc::install') }
  it { is_expected.to create_class('krb5::kdc::config') }
  it { is_expected.to create_class('krb5::kdc::service') }
  it { is_expected.to create_krb5__kdc__realm(facts[:networking][:domain]) }
  it { is_expected.to create_krb5__setting__realm(facts[:networking][:domain]) }
  it { is_expected.to contain_class('krb5::kdc::auto_keytabs') }

  it_behaves_like 'auto_keytab'
  # krb5::kdc::install
  it { is_expected.to contain_package('krb5-server') }
  # krb5::kdc::config
  it { is_expected.to create_file('/var/kerberos/krb5kdc/kdc.conf.simp.d') }
  it { is_expected.to create_file('/var/kerberos/krb5kdc/.princ_db_creds') }
  it { is_expected.to create_file('/var/kerberos/krb5kdc/kdc.conf') }
  it { is_expected.to create_file('/var/kerberos/krb5kdc/kdc.conf.d') }
  it { is_expected.to create_exec('initialize_principal_database') }
  it { is_expected.to create_krb5__setting('kdcdefaults:kdc_ports') }
  it { is_expected.to create_krb5__setting('kdcdefaults:kdc_tcp_ports') }
  it { is_expected.to create_krb5_acl('remove_default') }
  # krb5::kdc::service
  it { is_expected.to create_service('krb5kdc') }
  it { is_expected.to create_service('kadmin') }
end

shared_examples_for 'auto_keytab' do
  it { is_expected.to create_krb5kdc_auto_keytabs('__default__').with(realms: facts[:networking][:domain]) }
end

shared_examples_for 'selinux hotfix' do
  it { is_expected.to create_vox_selinux__module('krb5kdc_hotfix') }
end

shared_examples_for 'firewall' do
  it { is_expected.to contain_class('iptables') }
  it { is_expected.to create_iptables__listen__tcp_stateful('allow_kdc') }
  it { is_expected.to create_iptables__listen__udp('allow_kdc') }
  it { is_expected.to create_iptables__listen__udp('allow_kadmind') }
  it { is_expected.to create_iptables__listen__tcp_stateful('allow_kadmind') }
end

describe 'krb5::kdc' do
  context 'with supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          # to workaround service provider issues related to masking haveged
          # when tests are run on GitLab runners which are docker containers
          os_facts.merge({ haveged__rngd_enabled: false })
        end

        context 'with default parameters' do
          it_behaves_like 'common kdc config'
          it { is_expected.to contain_class('haveged') }
          it { is_expected.not_to contain_package('krb5-server-ldap') }
          it { is_expected.not_to contain_class('krb5::kdc::firewall') }

          unless os_facts.dig(:os, 'selinux').nil?
            it { is_expected.to contain_class('krb5::kdc::selinux_hotfix') }
          end
        end

        context 'with firewall = true, haveged = true, ldap = true' do
          let(:params) { { firewall: true, haveged: true, ldap: true } }

          it_behaves_like 'common kdc config'
          unless os_facts.dig(:os, 'selinux').nil?
            it_behaves_like 'selinux hotfix'
          end
          it { is_expected.to contain_class('haveged') }
          it { is_expected.to contain_package('krb5-server-ldap') }
          it { is_expected.to contain_class('krb5::kdc::firewall') }

          it_behaves_like 'firewall'
        end

        context 'when including the krb5::client class first' do
          let(:pre_condition) do
            'include krb5::client'
          end

          it_behaves_like 'common kdc config'
          unless os_facts.dig(:os, 'selinux').nil?
            it_behaves_like 'selinux hotfix'
          end
        end
      end
    end
  end
end
