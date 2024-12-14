# frozen_string_literal: true

require 'spec_helper'

describe 'krb5::client' do
  shared_examples_for 'common config' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('krb5') }
  end

  context 'with supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          # to workaround service provider issues related to masking haveged
          # when tests are run on GitLab runners which are docker containers
          os_facts.merge({ haveged__rngd_enabled: false })
        end

        context 'with default parameters' do
          it_behaves_like 'common config'

          # Based on the Hiera default.yaml
          it { is_expected.to create_krb5__setting__realm(facts[:networking][:domain]).with_admin_server(facts[:networking][:fqdn]) }
        end

        context 'with krb5::kdc declared' do
          let(:pre_condition) do
            'include krb5::kdc'
          end

          it_behaves_like 'common config'

          # Based on the Hiera default.yaml
          it { is_expected.to create_krb5__setting__realm(facts[:networking][:domain]).with_admin_server(facts[:networking][:fqdn]) }
        end

        context 'when passed a custom set of realms' do
          let(:params) do
            {
              realms: {
                'realm.one' => {
                  'admin_server' => 'admin.server.one'
                },
                'realm.two' => {
                  'admin_server' => 'admin.server.two',
                  'kdc' => 'kdc.server.two'
                }
              }
            }
          end

          it_behaves_like 'common config'

          # Based on the Hiera default.yaml
          it { is_expected.not_to create_krb5__setting__realm(facts[:networking][:domain]).with_admin_server(facts[:networking][:fqdn]) }

          it { is_expected.to create_krb5__setting__realm('realm.one').with_admin_server('admin.server.one') }

          it { is_expected.to create_krb5__setting__realm('realm.two').with_admin_server('admin.server.two') }
          it { is_expected.to create_krb5__setting__realm('realm.two').with_kdc('kdc.server.two') }
        end
      end
    end
  end
end
