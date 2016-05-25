require 'spec_helper'

describe 'krb5::kdc' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('krb5::kdc') }
        it { is_expected.to create_file('/var/kerberos/krb5kdc/kdc.conf') }
        it { is_expected.to create_class('haveged') }
        it {
          is_expected.to create_krb5__kdc__realm(facts[:domain]).that_requires('Class[haveged]')
        }

        context 'with iptables' do
          let(:params) {{
            :use_iptables => true
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('krb5::kdc::firewall') }
        end
      end
    end
  end
end
