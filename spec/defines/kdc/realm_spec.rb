require 'spec_helper'

describe 'krb5::kdc::realm' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        let(:pre_condition) { 'include ::krb5::kdc' }

        let(:title){ 'krbtestrealm' }

        it { is_expected.to compile.with_all_deps }

        it {
          resource_name = %(/var/kerberos/krb5kdc/kdc.conf.simp.d/#{title}__realm)

          is_expected.to create_file(resource_name)

          file_content = catalogue.resource(%(File[#{resource_name}]))[:content].dup.split("\n")

          expect(file_content).not_to be_empty

          # First line
          expect(file_content.shift).to match(/^\s*\[.+\]\s*/)
          # Second line
          expect(file_content.shift).to match(/^\s+#{title.upcase}\s+=\s+\{/)
          # Last line
          expect(file_content.pop).to match(/^\s+\}/)
          # Everything else should be string key/value pairs
          file_content.each do |line|
            expect(line).to match(/^\s+.+\s*=\s*.+$/)
            expect(line).not_to match(/\[.*\]/)
          end
        }

        context 'with tcp ports' do
          let(:params) {{
            :kdc_tcp_ports => ['2000','1234']
          }}

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to create_iptables__add_tcp_stateful_listen(%(#{title}_allow_kdc)).with({
              :order       => '11',
              :client_nets => ['1.2.3.4/32'],
              :dports      => params[:kdc_tcp_ports]
            })
          }
        end

        context 'with udp ports' do
          let(:params) {{
            :kdc_ports => ['2000','1234']
          }}

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to create_iptables__add_udp_listen(%(#{title}_allow_kdc)).with({
              :order       => '11',
              :client_nets => ['1.2.3.4/32'],
              :dports      => params[:kdc_ports]
            })
          }
        end
      end
    end
  end
end
