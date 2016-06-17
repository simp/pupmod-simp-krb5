module Puppet::Parser::Functions
  newfunction(:munge_krb5_conf_filename, :type => :rvalue, :arity => 1, :doc => <<-EOS
    When passed a string, returns a string that is safe to use as a filename
    for including in krb5 configuration files.
    EOS
  ) do |args|

    args.shift.to_s.strip.split('').map{ |chr|
      if chr =~ /^[A-Za-z0-9_-]$/
        chr = chr
      else
        chr = '-'
      end
    }.join
  end
end

# vim: set ts=2 sw=2 et :
