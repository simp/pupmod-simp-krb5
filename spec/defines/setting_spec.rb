# frozen_string_literal: true

require 'spec_helper'

describe 'krb5::setting' do
  context 'with supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          # to workaround service provider issues related to masking haveged
          # when tests are run on GitLab runners which are docker containers
          os_facts.merge({ haveged__rngd_enabled: false })
        end

        let(:pre_condition) { 'include ::krb5' }

        let(:title) { 'libdefaults:test_option' }

        let(:params) { { value: 'bar' } }

        it {
          expect(subject).to create_file(
            '/etc/krb5.conf.simp.d/libdefaults-test_option__setting',
          ).with_content(
            %r{\[libdefaults\]\n  test_option = bar},
          )
        }
      end
    end
  end
end
