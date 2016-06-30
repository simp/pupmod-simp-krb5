require 'spec_helper_acceptance'

test_name 'krb5 class'

describe 'krb5 class' do
  hosts.each do |host|

    context 'default setup' do
      install_package(host,'epel-release')

      let(:manifest) { %(include '::krb5') }

      it 'should work with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, {:catch_changes => true})
      end

      ['krb5-workstation','pam_krb5'].each do |pkg|
        it "package #{pkg} should be installed" do
          host.check_for_package(pkg)
        end
      end

      it 'should manage /etc/krb5.conf' do
        on(host, 'cat /etc/krb5.conf') do
          expect(stdout).to match(/This file managed by Puppet/)
        end
      end

      it 'should setup a default realm' do
        domain = fact_on(host, 'domain')
        on(host, "cat /etc/krb5.conf.simp.d/domain_realm-#{domain.gsub('.','-')}__setting") do
          expect(stdout).to match(/\[domain_realm\]\n\s+#{domain} = #{domain.upcase}/m)
        end
      end
    end

    context 'as a KDC' do
      let(:manifest) {
        <<-EOM
          class { 'krb5::kdc':
            client_nets => "#{fact('ipaddress')}/24",
          }
        EOM
      }

      it 'should work with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, {:catch_changes => true})
      end

      ['krb5kdc','kadmin'].each do |svc|
        it "should be running service #{svc}" do
          on(host, "puppet resource service #{svc}") do
            expect(stdout).to match(/ensure => 'running'/)
            expect(stdout).to match(/enable => '?true'?/)
          end
        end
      end

      it 'should manage /var/kerberos/krb5kdc/kdc.conf' do
        on(host, 'cat /var/kerberos/krb5kdc/kdc.conf') do
          expect(stdout).to match(/This file managed by Puppet/)
        end
      end

      it 'should manage /var/kerberos/krb5kdc/kdc.conf.simp.d/kdcdefaults-kdc_ports__setting' do
        on(host, 'cat /var/kerberos/krb5kdc/kdc.conf.simp.d/kdcdefaults-kdc_ports__setting') do
          expect(stdout).to match(/\[kdcdefaults\]\n\s+kdc_ports = 88,750/m)
        end
      end
    end

    context 'as a client' do
      it 'should not have any initial tickets' do
        on(host, 'klist', :acceptable_exit_codes => [1])
      end

      it 'should be able to get a ticket' do
        default_principal = on(host, 'cat /var/kerberos/krb5kdc/*.acl | tail -1').stdout.strip.split(/\s+/).first
        keytab = on(host, 'ls /var/kerberos/krb5kdc/*.keytab | tail -1').stdout.strip

        on(host, "kinit -k -t #{keytab} #{default_principal}")
      end

      it 'should have tickets after initialization' do
        on(host, 'klist')
      end
    end
  end
end
