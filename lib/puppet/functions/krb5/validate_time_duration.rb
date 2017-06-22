# Validates that the passed string is a valid krb5 time duration per
# http://web.mit.edu/kerberos/krb5-1.13/doc/basic/date_format.html#duration.
Puppet::Functions.create_function(:'krb5::validate_time_duration') do

  # @param time_duration Time duration string to be validated
  # @return [Undef]
  dispatch(:validate_time_duration) do
    required_param 'String', :time_duration
  end

  def validate_time_duration(time_duration)
    seconds = nil

    if time_duration =~ /^\d+$/
      seconds = time_duration.to_i
    elsif time_duration =~ /^\d+:\d+(:\d+)?$/
      require 'date'

      begin
        dt = DateTime.parse(time_duration)

        seconds = (dt.hour * 3600) + (dt.min * 60) + dt.sec
      rescue
        seconds = nil
      end
    else
      if time_duration =~ /^(?:(\d+)d)?(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$/
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
      raise Puppet::ParseError, ("'#{time_duration}' is not a valid krb5 time duration")
    end

    if seconds > 2147483647
      raise Puppet::ParseError, ("'#{time_duration}' is longer than 2147483647 seconds")
    end
  end
end

# vim: set ts=2 sw=2 et :
