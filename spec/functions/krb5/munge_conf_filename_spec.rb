# frozen_string_literal: true

require 'spec_helper'

describe 'krb5::munge_conf_filename' do
  testcases = {
    'libdefaults:test_option' => 'libdefaults-test_option',
    ' section-174 ' => 'section-174',
    'section foo' => 'section-foo',
    'section.foo' => 'section-foo', # TODO: why are dots not allowed in filename?
    'section/foo' => 'section-foo',
    'section\foo' => 'section-foo',
    'section[foo]' => 'section-foo-',
    'section<foo>' => 'section-foo-',
    '-`~!@#$%^&*()+={};\'",?|' => '_----------------------'
  }

  context 'with valid input' do
    testcases.each do |input, expected_output|
      it { is_expected.to run.with_params(input).and_return(expected_output) }
    end
  end
end
