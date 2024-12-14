# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:krb5kdc_auto_keytabs) do
  context 'when generating keys' do
    let :krb5kdc_auto_keytabs do
      Puppet::Type.type(:krb5kdc_auto_keytabs).new(name: '/var/kerberos/krb5kdc/auto_keytabs')
    end

    it 'successfullies activate' do
      expect { krb5kdc_auto_keytabs }.not_to raise_error
    end

    [:user, :group].each do |var|
      it "requires a string for the #{var}" do
        expect {
          Puppet::Type.type(:krb5kdc_auto_keytabs).new(
            :name => '/var/kerberos/krb5kdc/auto_keytabs',
            var => 'bob',
          )
        }.not_to raise_error

        expect {
          Puppet::Type.type(:krb5kdc_auto_keytabs).new(
            :name => '/var/kerberos/krb5kdc/auto_keytabs',
            var => ['bob'],
          )
        }.to raise_error(%r{must be a String})
      end
    end

    [:realms, :global_services].each do |var|
      it "requires a string or array for the #{var}" do
        expect {
          Puppet::Type.type(:krb5kdc_auto_keytabs).new(
            :name => '/var/kerberos/krb5kdc/auto_keytabs',
            var => 'bob',
          )
        }.not_to raise_error

        expect {
          Puppet::Type.type(:krb5kdc_auto_keytabs).new(
            :name => '/var/kerberos/krb5kdc/auto_keytabs',
            var => ['bob'],
          )
        }.not_to raise_error

        expect {
          Puppet::Type.type(:krb5kdc_auto_keytabs).new(
            :name => '/var/kerberos/krb5kdc/auto_keytabs',
            var => { 'bob' => 'baz' },
          )
        }.to raise_error(%r{must be a String or Array})
      end
    end

    it 'auto-upcases all realms' do
      expect(
        Puppet::Type.type(:krb5kdc_auto_keytabs).new(
          name: '/var/kerberos/krb5kdc/auto_keytabs',
          realms: ['realm', 'ReAlm2', 'REALM3'],
        )[:realms],
      ).to eql(['REALM', 'REALM2', 'REALM3'])
    end

    it 'requires a hash for the :hosts' do
      expect {
        Puppet::Type.type(:krb5kdc_auto_keytabs).new(
          name: '/var/kerberos/krb5kdc/auto_keytabs',
          hosts: {
            'foo.bar.baz' => {
              'ensure' => 'present'
            }
          },
        )
      }.not_to raise_error
    end

    it 'requires a valid ensure value for the :hosts hash' do
      expect {
        Puppet::Type.type(:krb5kdc_auto_keytabs).new(
          name: '/var/kerberos/krb5kdc/auto_keytabs',
          hosts: {
            'foo.bar.baz' => {
              'ensure' => 'garbage'
            }
          },
        )
      }.to raise_error(%r{must be})
    end

    it 'requires a valid realms value for the :hosts hash' do
      expect {
        Puppet::Type.type(:krb5kdc_auto_keytabs).new(
          name: '/var/kerberos/krb5kdc/auto_keytabs',
          hosts: {
            'foo.bar.baz' => {
              'ensure' => 'present',
              'realms' => ['FOO', 'BAR']
            }
          },
        )
      }.not_to raise_error
    end

    it 'requires a valid services value for the :hosts hash' do
      expect {
        Puppet::Type.type(:krb5kdc_auto_keytabs).new(
          name: '/var/kerberos/krb5kdc/auto_keytabs',
          hosts: {
            'foo.bar.baz' => {
              'ensure' => 'present',
              'services' => ['nfs', 'dns']
            }
          },
        )
      }.not_to raise_error
    end

    it 'upcases all realms in the :hosts hash' do
      expect(
        Puppet::Type.type(:krb5kdc_auto_keytabs).new(
          name: '/var/kerberos/krb5kdc/auto_keytabs',
          hosts: {
            'foo.bar.baz' => {
              'ensure' => 'present',
              'realms' => ['realm', 'ReAlm2', 'REALM3']
            }
          },
        )[:hosts]['foo.bar.baz']['realms'],
      ).to eql(['REALM', 'REALM2', 'REALM3'])
    end
  end

  context 'when using the default name' do
    let :krb5kdc_auto_keytabs do
      Puppet::Type.type(:krb5kdc_auto_keytabs).new(name: '__default__')
    end

    it 'successfullies activate' do
      expect { krb5kdc_auto_keytabs }.not_to raise_error
    end

    auto_dir = '/var/kerberos/krb5kdc/generated_keytabs'
    it "translates __default__ to #{auto_dir}" do
      expect(krb5kdc_auto_keytabs[:name]).to eql(auto_dir)
    end
  end
end
