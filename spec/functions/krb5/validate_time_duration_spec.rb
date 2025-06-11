# frozen_string_literal: true

require 'spec_helper'

describe 'krb5::validate_time_duration' do
  context 'with valid times of the form `h:m[:s]`' do
    it { is_expected.to run.with_params('3:30') }
    it { is_expected.to run.with_params('3:30:15') }
  end

  context 'with valid times of the form `NdNhNmNs`' do
    it { is_expected.to run.with_params('7s') }
    it { is_expected.to run.with_params('6m7s') }
    it { is_expected.to run.with_params('5h6m7s') }
    it { is_expected.to run.with_params('30d5h6m7s') }
  end

  context 'with valid times of the form `N`' do
    it { is_expected.to run.with_params('12') }
    it { is_expected.to run.with_params('1234567') }
  end

  context 'with invalid values' do
    it { is_expected.to run.with_params('').and_raise_error(%r{not a valid}) }
    it { is_expected.to run.with_params('-1').and_raise_error(%r{not a valid}) }
    it { is_expected.to run.with_params('534:100').and_raise_error(%r{not a valid}) }
    it { is_expected.to run.with_params('6m4s40d').and_raise_error(%r{not a valid}) }
  end

  context 'with times over `2147483647` seconds' do
    it { is_expected.to run.with_params('2147483648').and_raise_error(%r{longer than}) }
    it { is_expected.to run.with_params('32768d').and_raise_error(%r{longer than}) }
  end
end
