require 'spec_helper'

describe Puppet::Type.type(:krb5kdc_auto_keytabs) do

  context 'when generating keys' do
    let :krb5kdc_auto_keytabs do
      Facter.stubs(:value).with(:domain).returns('example.com')
      Puppet::Type.type(:krb5kdc_auto_keytabs).new(:name => '/var/kerberos/krb5kdc/auto_keytabs')
    end

    it 'should successfully activate' do
      expect { krb5kdc_auto_keytabs }.to_not raise_error
    end

    [:user, :group].each do |var|
      it "should require a string for the #{var}" do
        expect {
          Puppet::Type.type(:krb5kdc_auto_keytabs).new(
            :name => '/var/kerberos/krb5kdc/auto_keytabs',
            var   => 'bob'
          )
        }.to_not raise_error

        expect {
          Puppet::Type.type(:krb5kdc_auto_keytabs).new(
            :name => '/var/kerberos/krb5kdc/auto_keytabs',
            var   => ['bob']
          )
        }.to raise_error(/must be a String/)
      end
    end

    [:realms, :global_services].each do |var|
      it "should require a string or array for the #{var}" do
        expect {
          Puppet::Type.type(:krb5kdc_auto_keytabs).new(
            :name  => '/var/kerberos/krb5kdc/auto_keytabs',
            var    => 'bob'
          )
        }.to_not raise_error

        expect {
          Puppet::Type.type(:krb5kdc_auto_keytabs).new(
            :name  => '/var/kerberos/krb5kdc/auto_keytabs',
            var    => ['bob']
          )
        }.to_not raise_error

        expect {
          Puppet::Type.type(:krb5kdc_auto_keytabs).new(
            :name  => '/var/kerberos/krb5kdc/auto_keytabs',
            var    => {'bob' => 'baz'}
          )
        }.to raise_error(/must be a String or Array/)
      end
    end

    it 'should auto-upcase all realms' do
      expect(
        Puppet::Type.type(:krb5kdc_auto_keytabs).new(
          :name   => '/var/kerberos/krb5kdc/auto_keytabs',
          :realms => ['realm','ReAlm2','REALM3']
        )[:realms]
      ).to eql(['REALM','REALM2','REALM3'])
    end

    it "should require a hash for the :hosts" do
      expect {
        Puppet::Type.type(:krb5kdc_auto_keytabs).new(
          :name  => '/var/kerberos/krb5kdc/auto_keytabs',
          :hosts =>  {
            'foo.bar.baz' => {
              'ensure' => 'present'
            }
          }
        )
      }.to_not raise_error
    end

    it "should require a valid ensure value for the :hosts hash" do
      expect {
        Puppet::Type.type(:krb5kdc_auto_keytabs).new(
          :name  => '/var/kerberos/krb5kdc/auto_keytabs',
          :hosts =>  {
            'foo.bar.baz' => {
              'ensure' => 'garbage'
            }
          }
        )
      }.to raise_error(/must be/)
    end

    it "should require a valid realms value for the :hosts hash" do
      expect {
        Puppet::Type.type(:krb5kdc_auto_keytabs).new(
          :name  => '/var/kerberos/krb5kdc/auto_keytabs',
          :hosts =>  {
            'foo.bar.baz' => {
              'ensure' => 'present',
              'realms' => ['FOO','BAR']
            }
          }
        )
      }.to_not raise_error
    end

    it "should require a valid services value for the :hosts hash" do
      expect {
        Puppet::Type.type(:krb5kdc_auto_keytabs).new(
          :name  => '/var/kerberos/krb5kdc/auto_keytabs',
          :hosts =>  {
            'foo.bar.baz' => {
              'ensure' => 'present',
              'services' => ['nfs','dns']
            }
          }
        )
      }.to_not raise_error
    end

    it "should upcase all realms in the :hosts hash" do
      expect(
        Puppet::Type.type(:krb5kdc_auto_keytabs).new(
          :name  => '/var/kerberos/krb5kdc/auto_keytabs',
          :hosts =>  {
            'foo.bar.baz' => {
              'ensure' => 'present',
              'realms' => ['realm','ReAlm2','REALM3']
            }
          }
        )[:hosts]['foo.bar.baz']['realms']
      ).to eql(['REALM','REALM2','REALM3'])
    end
  end

  context 'when using the default name' do
    let :krb5kdc_auto_keytabs do
      Puppet::Type.type(:krb5kdc_auto_keytabs).new(:name => '__default__')
    end

    it 'should successfully activate' do
      expect { krb5kdc_auto_keytabs }.to_not raise_error
    end

    auto_dir = '/var/kerberos/krb5kdc/generated_keytabs'
    it "should translate __default__ to #{auto_dir}" do
      expect(krb5kdc_auto_keytabs[:name]).to eql(auto_dir)
    end
  end
end
