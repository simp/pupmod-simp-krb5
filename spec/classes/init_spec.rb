require 'spec_helper'

describe 'krb5' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('krb5') }
          it { is_expected.to create_file('/etc/krb5.conf') }

          # From krb5::config
          it { is_expected.to create_file('/etc/krb5.conf.d') }
          it { is_expected.to create_file('/etc/krb5.conf.simp.d').with_purge(true) }
          it { is_expected.to create_file('/etc/krb5.conf').with_content(%r(includedir /etc/krb5.conf.d)) }
          it { is_expected.to create_file('/etc/krb5.conf').with_content(%r(includedir /etc/krb5.conf.simp.d)) }
          it { is_expected.to contain_class('haveged') }
        end

        context 'with use_haveged => false' do
          let(:params) {{:use_haveged => false}}
          it { is_expected.to_not contain_class('haveged') }
        end

        context 'with invalid input' do
          let(:params) {{:use_haveged => 'invalid_input'}}
          it 'with use_haveged as a string' do
            expect {
              is_expected.to compile
            }.to raise_error(RSpec::Expectations::ExpectationNotMetError,/invalid_input" is not a boolean/)
          end
        end
      end
    end
  end
end
