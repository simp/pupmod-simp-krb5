require 'spec_helper'

describe 'krb5::setting' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:server_facts] = { :servername => 'puppet.bar.baz' } unless server_facts_hash
          facts
        end

        let(:pre_condition){ 'include ::krb5' }

        let(:title){ 'libdefaults:test_option' }

        let(:params){{ :value => 'bar' }}

        it {
          is_expected.to create_file(
            "/etc/krb5.conf.simp.d/libdefaults-test_option__setting"
          ).with_content(
            /\[libdefaults\]\n  test_option = bar/
          )
        }
      end
    end
  end
end
