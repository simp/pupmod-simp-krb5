require 'spec_helper'

shared_examples_for 'common config' do
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_class('krb5') }
  it { is_expected.to create_class('krb5::install').that_comes_before('Class[krb5::config]')}
  it { is_expected.to create_class('krb5::config') }
  it { is_expected.to create_file('/etc/krb5.conf') }

  #krb5 install
  it { is_expected.to create_package('krb5-workstation')}

  #krb5 config
  it { is_expected.to create_file('/etc/krb5.conf.d') }
  it { is_expected.to create_file('/etc/krb5.conf.simp.d').with_purge(true) }
  it { is_expected.to create_file('/etc/krb5.conf').with_content(%r(includedir /etc/krb5.conf.d)) }
  it { is_expected.to create_file('/etc/krb5.conf').with_content(%r(includedir /etc/krb5.conf.simp.d)) }
end


describe 'krb5' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:server_facts] = server_facts_hash unless (Gem::Version.new(Puppet.version) >= Gem::Version.new('5.0.0'))
          facts
        end

        context 'with default parameters' do
          it_should_behave_like 'common config'
          it { is_expected.to create_file('/etc/krb5.conf') }
          it { is_expected.to contain_class('haveged') }
        end

        context 'with haveged => true' do
          let(:params) {{:haveged => true}}
          it_should_behave_like 'common config'
          it { is_expected.to contain_class('haveged') }
        end
      end
    end
  end
end
