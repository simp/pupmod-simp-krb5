require 'spec_helper'

describe 'krb5' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('krb5') }
        it { is_expected.to create_file('/etc/krb5.conf') }

        # From krb5::config
        it { is_expected.to create_file('/etc/krb5.conf.d') }
        it { is_expected.to create_file('/etc/krb5.conf.simp.d').with_purge(true) }
        it { is_expected.to create_file('/etc/krb5.conf').with_content(%r(includedir /etc/krb5.conf.d)) }
        it { is_expected.to create_file('/etc/krb5.conf').with_content(%r(includedir /etc/krb5.conf.simp.d)) }
      end
    end
  end
end
