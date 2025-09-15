# frozen_string_literal: true

require 'spec_helper'

describe 'krb5::setting::domain_realm' do
  context 'with supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          # to workaround service provider issues related to masking haveged
          # when tests are run on GitLab runners which are docker containers
          os_facts.merge({ haveged__rngd_enabled: false })
        end

        let(:pre_condition) { 'include krb5' }

        let(:title) { 'mydomainrealm' }

        let(:params) do
          {
            realm: 'test.net'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_krb5__setting("domain_realm:#{title}") }
      end
    end
  end
end
