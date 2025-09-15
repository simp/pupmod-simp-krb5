# frozen_string_literal: true

#  Returns a string that is safe to use as a filename for including in
#  krb5 configuration files.
Puppet::Functions.create_function(:'krb5::munge_conf_filename') do
  # @param name String to be converted to a k4b6 configuration filename
  # @return String transformed filename
  dispatch(:munge_conf_filename) do
    required_param 'String', :name
  end

  def munge_conf_filename(name)
    filename = name.strip.split('').map { |chr|
      if %r{^[A-Za-z0-9_-]$}.match?(chr)
        chr
      else
        '-'
      end
    }.join
    # filenames that start with '-' are hard to work with
    # because the '-' gets confused with command options
    filename[0] = '_' if filename[0] == '-'
    filename
  end
end
