require 'spec_helper'

describe 'krb5::setting::realm' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          # to workaround service provider issues related to masking haveged
          # when tests are run on GitLab runners which are docker containers
          os_facts.merge( { :haveged__rngd_enabled => false } )
        end

        let(:pre_condition) { 'include krb5' }

        let(:title){ 'myrealm' }

        let(:params){{
          :admin_server => facts[:hostname]
        }}

        it { is_expected.to compile.with_all_deps }

        it {
          resource_name = %(/etc/krb5.conf.simp.d/#{title}__realm)

          is_expected.to create_file(resource_name)

          file_content = catalogue.resource(%(File[#{resource_name}]))[:content].dup.split("\n")

          expect(file_content).not_to be_empty

          # First line
          expect(file_content.shift).to match(/^\[realms\]$/)
          # Realm Start
          expect(file_content.shift).to match(/^\s+#{title.upcase}\s+=\s+\{/)
          # Realm end
          expect(file_content.pop).to match(/^\s+\}/)
          # Everything else should be string key/value pairs
          file_content.each do |line|
            expect(line).to match(/^\s+.+\s*=\s*.+$/)
            expect(line).not_to match(/\[.*\]/)
          end
        }
      end
    end
  end
end
