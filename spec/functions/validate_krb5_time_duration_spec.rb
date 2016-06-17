require 'spec_helper'

describe 'validate_krb5_time_duration' do
  context 'with valid times of the form `h:m[:s]`' do
    it do
      expect { subject.call(['3:30']) }.to_not raise_exception
      expect { subject.call(['3:30:15']) }.to_not raise_exception
    end
  end

  context 'with valid times of the form `NdNhNmNs`' do
    it do
      expect { subject.call(['7s']) }.to_not raise_exception
      expect { subject.call(['6m7s']) }.to_not raise_exception
      expect { subject.call(['5h6m7s']) }.to_not raise_exception
      expect { subject.call(['30d5h6m7s']) }.to_not raise_exception
    end
  end

  context 'with valid times of the form `N`' do
    it do
      expect { subject.call(['12']) }.to_not raise_exception
      expect { subject.call(['1234567']) }.to_not raise_exception
    end
  end

  context 'with invalid values' do
    it do
      expect { subject.call(['']) }.to raise_exception(/not a valid/)
      expect { subject.call(['-1']) }.to raise_exception(/not a valid/)
      expect { subject.call(['534:100']) }.to raise_exception(/not a valid/)
      expect { subject.call(['6m4s40d']) }.to raise_exception(/not a valid/)
    end
  end

  context 'with times over `2147483647` seconds' do
    it do
      expect { subject.call(['2147483648']) }.to raise_exception(/longer than/)
      expect { subject.call(['32768d']) }.to raise_exception(/longer than/)
    end
  end
end
