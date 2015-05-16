require 'spec_helper'

describe 'krb5::keytab' do

  let(:facts) {{
    :fqdn => 'test.example.domain'
  }}

  it { should create_class('krb5::keytab') }
  it { should create_file('/etc/krb5_keytabs') }
end
