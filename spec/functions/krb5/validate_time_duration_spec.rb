require 'spec_helper'

describe 'krb5::validate_time_duration' do
  context 'with valid times of the form `h:m[:s]`' do
    it do
      is_expected.to run.with_params('3:30')
      is_expected.to run.with_params('3:30:15')
    end
  end

  context 'with valid times of the form `NdNhNmNs`' do
    it do
      is_expected.to run.with_params('7s')
      is_expected.to run.with_params('6m7s')
      is_expected.to run.with_params('5h6m7s')
      is_expected.to run.with_params('30d5h6m7s')
    end
  end

  context 'with valid times of the form `N`' do
    it do
      is_expected.to run.with_params('12')
      is_expected.to run.with_params('1234567')
    end
  end

  context 'with invalid values' do
    it do
      is_expected.to run.with_params('').and_raise_error(/not a valid/)
      is_expected.to run.with_params('-1').and_raise_error(/not a valid/)
      is_expected.to run.with_params('534:100').and_raise_error(/not a valid/)
      is_expected.to run.with_params('6m4s40d').and_raise_error(/not a valid/)
    end
  end

  context 'with times over `2147483647` seconds' do
    it do
      is_expected.to run.with_params('2147483648').and_raise_error(/longer than/)
      is_expected.to run.with_params('32768d').and_raise_error(/longer than/)
    end
  end
end
