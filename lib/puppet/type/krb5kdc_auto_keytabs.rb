Puppet::Type.newtype(:krb5kdc_auto_keytabs) do
  @doc = <<-HERE
    Auto-generates principals and keytabs on a functional KDC and outputs the
    keytabs to a directory of the user's choosing.

    Can optionally take a hash of hosts, with associated principal metadata,
    to be created on the KDC. Will warn if you are attempting to add a host
    that does not have a valid REALM.
  HERE

  require 'puppet/parameter/boolean'

  ensurable do
    desc 'The state to enforce on the resource'

    defaultto(:present)

    newvalue(:present) do
      provider.sync_keytabs
    end

    newvalue(:generated) do
      provider.sync_keytabs
    end

    newvalue(:absent) do
      provider.delete_keytabs
    end
  end

  newparam(:name, :namevar => :true) do
    desc <<-EOM
      The output directory to which to write the keytabs

      If '__default__' will be set to either
      `/var/simp/environments/${environment}/site_files/krb5_files/files/keytabs` or
      `/var/kerberos/krb5kdc/generated_keytabs` depending on which target path
      exists.
    EOM

    validate do |value|
      unless (value == '__default__') || Puppet::Util.absolute_path?(value)
        raise(Puppet::Error, "'$name' must be an absolute path, not '#{value}'")
      end
    end

    munge do |value|
      if value == '__default__'
        value = '/var/kerberos/krb5kdc/generated_keytabs'

        if Puppet[:environment]
          target_dir = (File.join(
            '/var',
            'simp',
            'environments',
            Puppet[:environment],
            'site_files',
            'krb5_files',
            'files',
            'keytabs'
          ))

          if File.directory?(File.dirname(target_dir))
            value = target_dir
          end
        end
      end

      value
    end
  end

  newparam(:introspect, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc <<-EOM
      Attempt to discover, and create, all relevant keytabs from data on the
      Puppet server.

      This *will* create host principals for discovered entities if they do not
      exist already!

      This takes a best guess from the SIMP default PKI key locations:
        * `${environmentpath}/${environment}/keydist`
        * `/var/simp/environments/${environment}/site_files/pki_files/files/keydist`

      If `$environmentpath` is not set, then `$confdir` will be substituted for
      `${environmentpath}/${environment}`
    EOM
    defaultto(:true)
  end

  newparam(:all_known, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc <<-EOM
      Generate keytabs for any 'host/.*' entires known to the KDC.
    EOM
    defaultto(:false)
  end

  newparam(:user) do
    desc <<-EOM
      The user that should own the generated keytabs, defaults to
      '#{Puppet[:user]}' when installing into a Puppet Environment and 'root'
      otherwise.
    EOM

    defaultto('root')

    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "$user must be a String, not '#{value.class}'")
      end
    end

    munge do |value|
      if Puppet[:environmentpath] && (@resource[:name] =~ /^#{Puppet[:environmentpath]}/)
        value = Puppet[:user]
      end

      value
    end
  end

  newparam(:group) do
    desc <<-EOM
      The group that should own the generated keytabs, defaults to
      '#{Puppet[:group]}' when installing into a Puppet Environment and 'root'
      otherwise.
    EOM

    defaultto('group')

    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "$group must be a String, not '#{value.class}'")
      end
    end

    munge do |value|
      if Puppet[:environmentpath] && (@resource[:name] =~ /^#{Puppet[:environmentpath]}/)
        value = Puppet[:group]
      end

      value
    end
  end

  newparam(:realms, :array_matching => :all) do
    desc <<-EOM
      The realms under which the hosts should be generated
    EOM

    defaultto(Facter.value(:domain))

    validate do |value|
      unless (value.is_a?(String) || value.is_a?(Array)) || (Array(value).count{|x| !x.is_a?(String)} == 0)
        raise(Puppet::Error, "'$realms' must be a String or Array of Strings, not '#{value.class}'")
      end
    end

    munge do |value|
      Array(value).map(&:upcase)
    end
  end

  newparam(:global_services, :array_matching => :all) do
    desc <<-EOM
      The global services that should be applied to *every* auto-generated principal
    EOM

    validate do |value|
      unless (value.is_a?(String) || value.is_a?(Array)) || (Array(value).count{|x| !x.is_a?(String)} == 0)
        raise(Puppet::Error, "'$global_services' must be a String or Array, not '#{value.class}'")
      end
    end

    munge do |value|
      Array(value)
    end
  end

  newparam(:hosts) do
    desc <<-EOM
      A Hash of hosts that should be managed in the KDC.

      The Hash format should be as follows:

      {
        'fqdn' => {
          'ensure'   => ('absent' | 'present') # Required
          'realms'   => ['REALM1', 'REALM2']   # Optional. Will be auto-upcased
          'services' => ['svc1','svc2']        # Optional
        }
      }

      If '$global_services' is set, it will be added to the list of services for each host here.
    EOM

    validate do |value|
      unless value.is_a?(Hash)
        raise(Puppet::Error, "'$hosts' must be a Hash")
      end

      value.each_key do |host|
        unless ['absent','present'].include?(value[host]['ensure'])
          raise(Puppet::Error, "'#{host} => 'ensure' must be either 'absent' or 'present'")
        end

        if value[host]['realms'] && (Array(value[host]['realms']).count{|x| !x.is_a?(String)} != 0)
          raise(Puppet::Error, "'#{host} => 'realms' must be an Array of Strings")
        end

        if value[host]['services'] &&(Array(value[host]['services']).count{|x| !x.is_a?(String)} != 0)
          raise(Puppet::Error, "'#{host} => 'services' must be an Array of Strings")
        end
      end
    end

    munge do |value|
      value.each_key do |host|
        if value[host]['realms']
          value[host]['realms'] = value[host]['realms'].flatten.map(&:upcase)
        else
          value[host]['realms'] = []
        end

        value[host]['services'].flatten! if value[host]['services']

        if @resource[:global_services] && !@resource[:global_services].empty?
          value[host]['services'] ||= []
          value[host]['services'] += @resource[:global_services]
        else
          value[host]['services'] = []
        end
      end

      value
    end
  end

  newparam(:purge, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc <<-EOM
      Remove all unmanaged keytabs from the '$name' directory
    EOM
    defaultto(:true)
  end
end
