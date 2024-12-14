# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'common realm config' do
  it { is_expected.to compile.with_all_deps }

  it {
    resource_name = %(/var/kerberos/krb5kdc/kdc.conf.simp.d/#{title}__realm)
    expect(subject).to create_file(resource_name)
    file_content = catalogue.resource(%(File[#{resource_name}]))[:content].dup.split("\n")
    expect(file_content).not_to be_empty
    # First line
    expect(file_content.shift).to match(%r{^\s*\[.+\]\s*})
    # Second line
    expect(file_content.shift).to match(%r{^\s+#{title.upcase}\s+=\s+\{})
    # Last line
    expect(file_content.pop).to match(%r{^\s+\}})
    # Everything else should be string key/value pairs
    file_content.each do |line|
      expect(line).to match(%r{^\s+.+\s*=\s*.+$})
      expect(line).not_to match(%r{\[.*\]})
    end
  }
end

describe 'krb5::kdc::realm' do
  context 'with supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          # to workaround service provider issues related to masking haveged
          # when tests are run on GitLab runners which are docker containers
          os_facts.merge({ haveged__rngd_enabled: false })
        end

        let(:pre_condition) { 'include krb5::kdc' }
        let(:title) { 'krbtestrealm' }

        context 'with catalysts disabled and initialize = false' do
          let(:hieradata) { 'no_auto_initialize' }

          it_behaves_like 'common realm config'
          it { is_expected.not_to create_iptables__listen__tcp_stateful('krbtestrealm_allow_kdc') }
          it { is_expected.not_to create_iptables__listen__udp('krbtestrealm_allow_kdc') }
          it { is_expected.not_to create_krb5_acl('krbtestrealm_puppet_auto_admin') }

          it {
            pending
            expect(subject).not_to create_exec('add_admin_principal_puppet_auto')
          }

          it {
            pending
            expect(subject).not_to create_exec('create_admin_principal_puppet_auto_keytab')
          }
        end

        context 'with firewall = true and initialize = true' do
          let(:hieradata) { 'firewall' }
          let(:params) { { initialize: true, auto_principal: 'auto_principal_bob' } }

          it_behaves_like 'common realm config'
          context 'with tcp ports' do
            let(:params) { { kdc_tcp_ports: [2000, 1234] } }

            it {
              expect(subject).to create_iptables__listen__tcp_stateful(%(#{title}_allow_kdc)).with({
                                                                                                     order: 11,
                                                                                                     trusted_nets: ['1.2.3.4/32'],
                                                                                                     dports: params[:kdc_tcp_ports]
                                                                                                   })
            }
          end

          context 'with udp ports' do
            let(:params) { { kdc_ports: [2000, 1234] } }

            it {
              expect(subject).to create_iptables__listen__udp(%(#{title}_allow_kdc)).with({
                                                                                            order: 11,
                                                                                            trusted_nets: ['1.2.3.4/32'],
                                                                                            dports: params[:kdc_ports]
                                                                                          })
            }
          end

          it { is_expected.to create_krb5_acl('krbtestrealm_puppet_auto_admin') }
          it { is_expected.to create_exec('add_admin_principal_auto_principal_bob') }
          it { is_expected.to create_exec('create_admin_principal_auto_principal_bob_keytab') }
        end
      end
    end
  end
end
