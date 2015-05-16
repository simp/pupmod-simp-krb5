require 'spec_helper'

describe 'krb5::kdc' do

  it { should create_class('krb5::kdc') }
  it { should create_file('/var/kerberos/krb5kdc/kdc.conf') }
end
