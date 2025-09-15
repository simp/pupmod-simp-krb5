# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:krb5kdc_auto_keytabs).provider(:generate)

describe provider_class do
  let(:test_host) { 'foo.bar.baz' }
  let(:target_dir) { '/tmp/krb5kdc_auto_keytabs.test' }
  let(:test_realm) { 'TEST.REALM' }

  let(:add_principal) do
    <<~ADD_PRINC
      Authenticating as principal puppet_auto/admin@#{test_realm} with password.
      WARNING: no policy specified for host/#{test_host}@#{test_realm}; defaulting to no policy
      Principal "host/#{test_host}@#{test_realm}" created.
    ADD_PRINC
  end

  let(:list_principals) do
    <<~LIST_PRINC
      Authenticating as principal puppet_auto/admin@#{test_realm} with password.
      K/M@#{test_realm}
      host/#{test_host}@#{test_realm}
      nfs/#{test_host}@#{test_realm}
      puppet_auto/admin@#{test_realm}
    LIST_PRINC
  end

  let(:get_principal) do
    <<~GET_PRINC
      Authenticating as principal puppet_auto/admin@#{test_realm} with password.
      Principal: host/#{test_host}@#{test_realm}
      Expiration date: [never]
      Last password change: Thu Jun 09 22:31:01 UTC 2016
      Password expiration date: [none]
      Maximum ticket life: 1 day 00:00:00
      Maximum renewable life: 0 days 00:00:00
      Last modified: Thu Jun 09 22:31:01 UTC 2016 (puppet_auto/admin@#{test_realm})
      Last successful authentication: [never]
      Last failed authentication: [never]
      Failed password attempts: 0
      Number of keys: 2
      Key: vno 1, aes256-cts-hmac-sha1-96, no salt
      Key: vno 1, aes128-cts-hmac-sha1-96, no salt
      MKey: vno 1
      Attributes:
      Policy: [none]
    GET_PRINC
  end

  let(:add_keytab) do
    <<~ADD_KEYTAB
      Authenticating as principal puppet_auto/admin@#{test_realm} with password.
      Entry for principal host/#{test_host} with kvno 1, encryption type aes256-cts-hmac-sha1-96 added to keytab WRFILE:test.keytab.
      Entry for principal host/#{test_host} with kvno 1, encryption type aes128-cts-hmac-sha1-96 added to keytab WRFILE:test.keytab.
    ADD_KEYTAB
  end

  let(:resource) do
    Puppet::Type.type(:krb5kdc_auto_keytabs).new(
      {
        name: '__default__',
        realms: test_realm,
        provider: described_class.name
      },
    )
  end

  let(:provider) { resource.provider }

  before :each do
    allow(Puppet).to receive(:[]).with(:confdir).and_return(target_dir)
    allow(Puppet).to receive(:[]).with(:environmentpath).and_return(nil)
    allow(Puppet).to receive(:[]).with(:environment).and_return('')
    allow(Puppet::Util).to receive(:which).with('kadmin.local').and_return('/usr/sbin/kadmin.local')

    allow(provider).to receive(:execute).with(%r{list_principals}).and_return(list_principals)
    allow(provider).to receive(:execute).with(%r{get_principal}).and_return(get_principal)
    allow(provider).to receive(:execute).with(%r{add_principal}).and_return(add_principal)
    allow(provider).to receive(:execute).with(%r{ktadd}).and_return(add_keytab)

    allow(provider).to receive_messages(introspect_hosts: [test_host], clean_files: true)

    allow(File).to receive(:exist?).with(%r{\.keytab}).and_return(true)
    allow(File).to receive(:exist?).with(%r{\.kvno}).and_return(false)
    allow(File).to receive(:open).with(%r{\.kvno}, 'w').and_return(true)

    allow(FileUtils).to receive_messages(mkdir_p: true, chmod: true, chown: true, mv: true)
  end

  context 'when generating keytabs' do
    it 'does not have any errors' do
      expect(provider).to receive(:execute).with(%r{ktadd.*.+/#{test_host}@#{test_realm}})
      expect(provider).not_to receive(:execute).with(%r{add_principal.*.+/#{test_host}@#{test_realm}})

      provider.exists?
      provider.sync_keytabs
    end
  end

  context 'with a matching kvno file' do
    it 'does not have any errors' do
      allow(File).to receive(:exist?).with(%r{\.kvno}).and_return(true)
      allow(File).to receive(:read).with(%r{\.kvno}).and_return("1\n1\n")

      expect(provider).not_to receive(:execute).with(%r{ktadd.*.+/#{test_host}@#{test_realm}})
      expect(provider).not_to receive(:execute).with(%r{add_principal.*.+/#{test_host}@#{test_realm}})

      provider.exists?
      provider.sync_keytabs
    end
  end

  context 'with a non-matching kvno file' do
    it 'does not have any errors' do
      allow(File).to receive(:exist?).with(%r{\.kvno}).and_return(true)
      allow(File).to receive(:read).with(%r{\.kvno}).and_return("1\n2\n")

      expect(provider).to receive(:execute).with(%r{ktadd.*.+/#{test_host}@#{test_realm}}).once
      expect(provider).not_to receive(:execute).with(%r{add_principal.*.+/#{test_host}@#{test_realm}})

      provider.exists?
      provider.sync_keytabs
    end
  end

  context 'when generating keytabs for unknown principals' do
    let(:list_principals) do
      <<~LIST_PRINC
        Authenticating as principal puppet_auto/admin@#{test_realm} with password.
        K/M@#{test_realm}
        puppet_auto/admin@#{test_realm}
      LIST_PRINC
    end

    it 'does not have any errors' do
      expect(provider).to receive(:execute).with(%r{ktadd.*.+/#{test_host}@#{test_realm}}).once
      expect(provider).to receive(:execute).with(%r{add_principal.*.+/#{test_host}@#{test_realm}}).once

      provider.exists?
      provider.sync_keytabs
    end
  end

  context 'when generating keytabs for all known principals' do
    let(:resource) do
      Puppet::Type.type(:krb5kdc_auto_keytabs).new(
        {
          name: '__default__',
          all_known: true,
          realms: test_realm,
          provider: described_class.name
        },
      )
    end

    it 'does not have any errors' do
      allow(provider).to receive(:introspect_hosts).and_return([])

      expect(provider).to receive(:execute).with(%r{ktadd.*.+/#{test_host}@#{test_realm}}).twice
      expect(provider).to receive(:execute).with(%r{add_principal.*.+/#{test_host}@#{test_realm}}).never

      provider.exists?
      provider.sync_keytabs
    end
  end
end
