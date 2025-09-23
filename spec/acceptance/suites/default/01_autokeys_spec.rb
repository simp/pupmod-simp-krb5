# frozen_string_literal: true

require 'spec_helper_acceptance'

test_name 'krb5 class autokeys'

describe 'krb5 class autokeys' do
  hosts.each do |host|
    context 'when autogenerating from PKI keys' do
      let(:manifest) do
        <<~MANIFEST
          class { 'krb5::kdc':
            trusted_nets => ["#{fact('ipaddress')}/24"]
          }
        MANIFEST
      end

      let(:hieradata) do
        <<~HIERADATA
          ---
          krb5::kdc::auto_keytabs::introspect : true
        HIERADATA
      end

      let(:puppet_confdir) do
        on(host, %(puppet config print confdir)).stdout.strip
      end
      let(:puppet_codedir) do
        on(host, %(puppet config print codedir)).stdout.strip
      end

      # Prep to generate keys from the SIMP PKI space
      it 'is able to setup a mock SIMP environment' do
        on(host, %(puppet config set environmentpath '#{puppet_codedir}/environments:#{puppet_confdir}/environments:/var/simp/environments'))
        on(host, %(mkdir -p "#{puppet_confdir}/environments/production/modules"))

        # Old Location
        on(host, %(mkdir -p "#{puppet_confdir}/environments/production/keydist/fake_host1.some.domain"))

        # New Location
        on(host, %(mkdir -p "/var/simp/environments/production/site_files/pki_files/files/keydist/fake_host2.some.domain"))
      end

      it 'works with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, { catch_changes: true })
      end

      it 'creates keytabs for the hosts' do
        ['fake_host1.some.domain', 'fake_host2.some.domain'].each do |hname|
          host_principals = on(host, %(kadmin.local -q 'list_principals')).stdout.strip.split("\n").join(':')
          expect(host_principals).to match(%r{:host/#{hname}@})

          on(host, %(ls /var/kerberos/krb5kdc/generated_keytabs/#{hname}/krb5.keytab))
        end
      end

      it 'creates keytabs for the hosts in the krb5 site_files space if it exists' do
        on(host, %(mkdir -p "/var/simp/environments/production/site_files/krb5_files/files"))

        apply_manifest_on(host, manifest, catch_failures: true)

        ['fake_host1.some.domain', 'fake_host2.some.domain'].each do |hname|
          host_principals = on(host, %(kadmin.local -q 'list_principals')).stdout.strip.split("\n").join(':')
          expect(host_principals).to match(%r{:host/#{hname}@})

          on(host, %(ls /var/simp/environments/production/site_files/krb5_files/files/keytabs/#{hname}/krb5.keytab))
        end
      end

      it 'does not generate keytabs for all known host principals by default' do
        on(host, %(kadmin.local -q "add_principal -randkey +allow_renewable +allow_svr host/cool_test_bro"))

        generated_hosts = on(host, %(ls /var/simp/environments/production/site_files/krb5_files/files/keytabs)).stdout.strip

        expect(generated_hosts).not_to match(%r{cool_test_bro@}m)
      end

      it 'generates keytabs for all known host principals if set' do
        hieradata =
          <<~HIERADATA
            ---
            krb5::kdc::auto_keytabs::introspect : true
            krb5::kdc::auto_keytabs::all_known : true
          HIERADATA

        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)

        on(host, %(ls /var/simp/environments/production/site_files/krb5_files/files/keytabs/cool_test_bro/krb5.keytab))
      end
    end
  end
end
