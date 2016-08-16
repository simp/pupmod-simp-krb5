require 'spec_helper_acceptance'

test_name 'krb5 class autokeys'

describe 'krb5 class autokeys' do

  hosts.each do |host|
    context 'autogenerating from PKI keys' do
      let(:manifest) {
        <<-EOM
          class { 'krb5::kdc':
            client_nets => "#{fact('ipaddress')}/24",
          }
        EOM
      }

      let(:hieradata) {
        <<-EOM
---
krb5::kdc::auto_keytabs::introspect : true
        EOM
      }

      let(:puppet_confdir) {
        on(host, %(puppet config print confdir)).stdout.strip
      }

      # Prep to generate keys from the SIMP PKI space
      it 'should be able to setup a mock SIMP environment' do
        on(host, %(puppet config set environmentpath '#{puppet_confdir}/environments:/var/simp/environments'))
        on(host, %(mkdir -p "#{puppet_confdir}/environments/production/modules"))

        # Old Location
        on(host, %(mkdir -p "#{puppet_confdir}/environments/production/keydist/fake_host1.some.domain"))

        # New Location
        on(host, %(mkdir -p "/var/simp/environments/production/site_files/pki_files/files/keydist/fake_host2.some.domain"))
      end

      it 'should work with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, {:catch_changes => true})
      end

      it 'should create keytabs for the hosts' do
        ['fake_host1.some.domain', 'fake_host2.some.domain'].each do |hname|
          host_principals = on(host, %(kadmin.local -q 'list_principals')).stdout.strip.split("\n").join(':')
          expect(host_principals).to match(%r(:host/#{hname}@))

          on(host, %(ls /var/kerberos/krb5kdc/generated_keytabs/#{hname}/krb5.keytab))
        end
      end

      it 'should create keytabs for the hosts in the krb5 site_files space if it exists' do
        on(host, %(mkdir -p "/var/simp/environments/production/site_files/krb5_files/files"))

        apply_manifest_on(host, manifest, :catch_failures => true)

        ['fake_host1.some.domain', 'fake_host2.some.domain'].each do |hname|
          host_principals = on(host, %(kadmin.local -q 'list_principals')).stdout.strip.split("\n").join(':')
          expect(host_principals).to match(%r(:host/#{hname}@))

          on(host, %(ls /var/simp/environments/production/site_files/krb5_files/files/keytabs/#{hname}/krb5.keytab))
        end
      end

      it 'should not generate keytabs for all known host principals by default' do
        on(host, %(kadmin.local -q "add_principal -randkey +allow_renewable +allow_svr host/cool_test_bro"))

        generated_hosts = on(host, %(ls /var/simp/environments/production/site_files/krb5_files/files/keytabs)).stdout.strip

        expect(generated_hosts).to_not match(/cool_test_bro@/m)
      end

      it 'should generate keytabs for all known host principals if set' do
        hieradata =
        <<-EOM
---
krb5::kdc::auto_keytabs::introspect : true
krb5::kdc::auto_keytabs::all_known : true
        EOM

        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)

        on(host, %(ls /var/simp/environments/production/site_files/krb5_files/files/keytabs/cool_test_bro/krb5.keytab))
      end
    end
  end
end
