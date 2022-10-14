# frozen_string_literal: true

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

    case time_duration
    when %r{^\d+$}
      seconds = time_duration.to_i
    when %r{^\d+:\d+(:\d+)?$}
      require 'date'

      begin
        dt = DateTime.parse(time_duration)

        seconds = (dt.hour * 3600) + (dt.min * 60) + dt.sec
      rescue StandardError
        seconds = nil
      end
    when %r{^(?:(\d+)d)?(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$}
      time = [Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3), Regexp.last_match(4)]

      # Something went wrong, ignore everything
      unless time.count { |t| t.nil? } == time.count

        time.map! { |x| x.nil? ? 0 : x.to_i }

        seconds = 0
        seconds += time[0] * 86_400
        seconds += time[1] * 3600
        seconds += time[2] * 60
        seconds += time[3]
      end
    end

    raise Puppet::ParseError, "'#{time_duration}' is not a valid krb5 time duration" unless seconds

    raise Puppet::ParseError, "'#{time_duration}' is longer than 2147483647 seconds" if seconds > 2_147_483_647
  end
end

# vim: set ts=2 sw=2 et :
