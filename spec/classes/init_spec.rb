# frozen_string_literal: true

require 'spec_helper'

describe 'krb5' do
  shared_examples_for 'common config' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('krb5') }
    it { is_expected.to create_class('krb5::install').that_comes_before('Class[krb5::config]') }
    it { is_expected.to create_class('krb5::config') }
    it { is_expected.to create_file('/etc/krb5.conf') }

    # krb5 install
    it { is_expected.to create_package('krb5-workstation') }

    # krb5 config
    it { is_expected.to create_file('/etc/krb5.conf.d') }
    it { is_expected.to create_file('/etc/krb5.conf.simp.d').with_purge(true) }
    it { is_expected.to create_file('/etc/krb5.conf').with_content(%r{includedir /etc/krb5.conf.d}) }
    it { is_expected.to create_file('/etc/krb5.conf').with_content(%r{includedir /etc/krb5.conf.simp.d}) }
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
          it { is_expected.to create_file('/etc/krb5.conf') }
          it { is_expected.to contain_class('haveged') }
        end

        context 'with haveged => true' do
          let(:params) { { haveged: true } }

          it_behaves_like 'common config'
          it { is_expected.to contain_class('haveged') }
        end
      end
    end
  end
end
