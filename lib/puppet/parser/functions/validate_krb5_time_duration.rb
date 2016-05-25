module Puppet::Parser::Functions
  newfunction(:validate_krb5_time_duration, :arity => 1, :doc => <<-EOS
      Validates that the passed string is a valid krb5 time duration per
      http://web.mit.edu/kerberos/krb5-1.13/doc/basic/date_format.html#duration.
    EOS
  ) do |args|

    value = args.shift

    seconds = nil

    # Seconds
    if value =~ /^\d+$/
      seconds = value.to_i
    elsif value =~ /^\d+:\d+(:\d+)?$/
      require 'date'

      begin
        dt = DateTime.parse(value)

        seconds = (dt.hour * 3600) + (dt.min * 60) + dt.sec
      rescue
        seconds = nil
      end
    else
      if value =~ /^(?:(\d+)d)?(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$/
        time = [$1, $2, $3, $4]

        # Something went wrong, ignore everything
        unless time.count{|t| t.nil?} == time.count

          time.map!{|x| x = x.nil? ? 0 : x.to_i }

          seconds = 0
          seconds += time[0] * 86400
          seconds += time[1] * 3600
          seconds += time[2] * 60
          seconds += time[3]
        end
      end
    end

    unless seconds
      raise Puppet::ParseError, ("'#{value}' is not a valid krb5 time duration") 
    end

    if seconds > 2147483647
      raise Puppet::ParseError, ("'#{value}' is longer than 2147483647 seconds") 
    end
  end
end

# vim: set ts=2 sw=2 et :
