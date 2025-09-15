# frozen_string_literal: true

require 'spec_helper'

describe 'krb5::keytab' do
  context 'with supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          # to workaround service provider issues related to masking haveged
          # when tests are run on GitLab runners which are docker containers
          os_facts.merge({ haveged__rngd_enabled: false })
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('krb5::keytab') }
        it { is_expected.to create_file('/etc/krb5_keytabs') }
      end
    end
  end
end
