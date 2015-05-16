require 'spec_helper'

describe 'krb5' do

  it { should create_class('krb5') }
  it { should create_file('/etc/krb5.conf') }
end
