require 'spec_helper'

describe 'krb5::setting::domain_realm' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:server_facts] = server_facts_hash unless (Gem::Version.new(Puppet.version) >= Gem::Version.new('5.0.0'))
          facts
        end

        let(:pre_condition) { 'include ::krb5' }

        let(:title){ 'mydomainrealm' }

        let(:params){{
          :realm => 'test.net'
        }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_krb5__setting("domain_realm:#{title}") }
      end
    end
  end
end
