# frozen_string_literal: true

require 'spec_helper_acceptance'

test_name 'krb5 class'

describe 'krb5 class' do
  hosts.each do |host|
    context 'with default setup' do
      let(:manifest) { %(include 'krb5') }

      it 'works with no errors' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, { catch_changes: true })
      end

      ['krb5-workstation', 'pam_krb5'].each do |pkg|
        it "package #{pkg} should be installed" do
          host.check_for_package(pkg)
        end
      end

      it 'manages /etc/krb5.conf' do
        on(host, 'cat /etc/krb5.conf') do
          expect(stdout).to match(%r{This file managed by Puppet})
        end
      end

      it 'setups a default realm' do
        domain = fact_on(host, 'domain')
        on(host, "cat /etc/krb5.conf.simp.d/domain_realm-#{domain.tr('.', '-')}__setting") do
          expect(stdout).to match(%r{\[domain_realm\]\n\s+#{domain} = #{domain.upcase}}m)
        end
      end
    end

    context 'when acting as a KDC' do
      let(:manifest) do
        <<~MANIFEST
          class { 'krb5::kdc':
            trusted_nets => ["#{fact('ipaddress')}/24"],
          }
        MANIFEST
      end

      it 'works with no errors' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, { catch_changes: true })
      end

      ['krb5kdc', 'kadmin'].each do |svc|
        it "is running service #{svc}" do
          on(host, "puppet resource service #{svc}") do
            expect(stdout).to match(%r{ensure\s*=> 'running'})
            expect(stdout).to match(%r{enable\s*=> '?true'?})
          end
        end
      end

      it 'manages /var/kerberos/krb5kdc/kdc.conf' do
        on(host, 'cat /var/kerberos/krb5kdc/kdc.conf') do
          expect(stdout).to match(%r{This file managed by Puppet})
        end
      end

      it 'manages /var/kerberos/krb5kdc/kdc.conf.simp.d/kdcdefaults-kdc_ports__setting' do
        on(host, 'cat /var/kerberos/krb5kdc/kdc.conf.simp.d/kdcdefaults-kdc_ports__setting') do
          expect(stdout).to match(%r{\[kdcdefaults\]\n\s+kdc_ports = 88,750}m)
        end
      end
    end

    context 'when acting as a client' do
      it 'does not have any initial tickets' do
        on(host, 'klist', acceptable_exit_codes: [1])
      end

      it 'is able to get a ticket' do
        default_principal = on(host, 'cat /var/kerberos/krb5kdc/*.acl | tail -1').stdout.strip.split(%r{\s+}).first
        keytab = on(host, 'ls /var/kerberos/krb5kdc/*.keytab | tail -1').stdout.strip

        on(host, "kinit -k -t #{keytab} #{default_principal}")
      end

      it 'has tickets after initialization' do
        on(host, 'klist')
      end
    end
  end
end
