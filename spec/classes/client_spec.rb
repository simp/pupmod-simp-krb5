require 'spec_helper'

describe 'krb5::client' do
  shared_examples_for 'common config' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('krb5') }
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:server_facts] = server_facts_hash unless (Gem::Version.new(Puppet.version) >= Gem::Version.new('5.0.0'))
          facts
        end

        context 'with default parameters' do
          it_should_behave_like 'common config'

          # Based on the Hiera default.yaml
          it { is_expected.to create_krb5__setting__realm(facts[:domain]).with_admin_server(facts[:fqdn]) }
        end

        context 'with krb5::kdc declared' do
          let(:pre_condition) do
            'include krb5::kdc'
          end

          it_should_behave_like 'common config'

          # Based on the Hiera default.yaml
          it { is_expected.to create_krb5__setting__realm(facts[:domain]).with_admin_server(facts[:fqdn]) }
        end

        context 'when passed a custom set of realms' do
          let(:params) {{
            :realms => {
              'realm.one' => {
                'admin_server' => 'admin.server.one'
              },
              'realm.two' => {
                'admin_server' => 'admin.server.two',
                'kdc'          => 'kdc.server.two'
              }
            }
          }}

          it_should_behave_like 'common config'

          # Based on the Hiera default.yaml
          it { is_expected.to_not create_krb5__setting__realm(facts[:domain]).with_admin_server(facts[:fqdn]) }

          it { is_expected.to create_krb5__setting__realm('realm.one').with_admin_server('admin.server.one') }

          it { is_expected.to create_krb5__setting__realm('realm.two').with_admin_server('admin.server.two') }
          it { is_expected.to create_krb5__setting__realm('realm.two').with_kdc('kdc.server.two') }
        end
      end
    end
  end
end
