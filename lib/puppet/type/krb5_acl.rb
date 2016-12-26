Puppet::Type.newtype(:krb5_acl) do
  @doc = 'Manages krb5 kadmind ACL entries per kadmind(8). When removing an
          entry, you can specify a regex for the operation_target and all
          associated entries will be removed.'

  ensurable

  def initialize(args)
    super
    found_resource = nil
    if not catalog.resources.find_all { |r|
      r.is_a?(Puppet::Type.type(:krb5_acl)) and
      r[:target] == self[:target] and
      r[:principal] == self[:principal] and
      r[:operation_target] == self[:operation_target] and
      found_resource = r
    }.empty?
      msg = "Duplicate declaration: Krb5_acl with target='#{self[:target]}', principal='#{self[:principal]}', and operation_target='#{self[:operation_target]}' is already declared"

      msg << " in file #{found_resource.file} at line #{found_resource.line}" if found_resource.file and found_resource.line

      msg << "; cannot redeclare" if self.line or self.file

      raise Puppet::Resource::Catalog::DuplicateResourceError.new(msg)
    end
  end

  def finish
    super
  end

  newparam(:name) do
    isnamevar
    desc "A required, but meaningless, name."
  end

  newparam(:target) do
    desc "The ACL file upon which to operate"
    defaultto('/var/kerberos/krb5kdc/kadm5.acl')

    validate do |value|
      value[0].chr == '/' or fail Puppet::Error, "'#{value}' is not a fully qualified 'target'"
    end

    munge do |value|
      if value =~ /(.*)@(.*)/
        value = "#{$1}@#{$2.upcase}"
      end

      value
    end
  end

  newparam(:principal) do
    desc "The partially, or fully, qualified Kerberos 5 principal name. This
          is what must appear as the usual 'name' of the resource."

    validate do |value|
      ( value[0].chr == '/' or value.count('@') > 1 ) and fail Puppet::Error, "#{value} is not of the form component/component/component[@realm]"
    end

    munge do |value|
      if value =~ /(.*)@(.*)/
        value = "#{$1}@#{$2.upcase}"
      end

      value
    end
  end

  newparam(:operation_target) do
    desc "An optional partially, or fully, qualified Kerberos 5 principal
          name upon which 'principal' is allowed to operate. If this is
          specified, the 'principal', 'operation_mask', and 'ensure' options
          will be restricted. This must be specified as a ruby regex without
          '/' in the case of ensure => 'absent'."

    # This has to have *something* since it's a namevar, so we default it to
    # 'undef' and act appropriately in the provider.
    defaultto('undef')

    munge do |value|
      if resource[:ensure] == 'absent'
        value[0].chr != '^' and value = '^' + value
        value[-1].chr != '$' and value = value + '$'
      end

      value
    end

    validate do |value|
      if resource[:ensure] == 'absent'
        if value[0].chr == '/' or value[-1].chr == '/'
          fail Puppet::Error, "'operation_target' regexes should not start or end with '/'"
        end
        begin
          Regexp.new(value)
        rescue
          fail Puppet::Error, "'operation_target' does not contain a valid regex"
        end
      else
        if value =~ /[!@#\$%^&*\(\)+=]/
          fail Puppet::Error, "'operation_target' does not look like a valid Kerberos 5 principal."
        end

        ( value[0].chr == '/' or value.count('@') > 1 ) and fail Puppet::Error, "'operation_target' must be of the form component/component/component[@realm]"
      end
    end
  end

  newproperty(:operation_mask) do
    desc "The operation mask per kadmind(8). Be aware that lower case activates a mask and upper case deactivates it."
    newvalues(/^([admcilpADMCILP]+|[x*])$/)

    munge do |value|
      value.split('').sort.uniq
    end

    validate do |value|
      t_val = value.split('')
      t_val.each do |x|
        next if x == '*'
        if t_val.include?(x.swapcase)
          fail Puppet::Error, "operation_mask options '#{x}' and '#{x.swapcase}' are mutually exclusive"
        end
      end
    end

    def insync?(is)
      is == @should.join
    end
  end

  autorequire(:file) do
    File.dirname(self[:target])
  end

  autonotify(:service) do
    ['kadmin']
  end
end
