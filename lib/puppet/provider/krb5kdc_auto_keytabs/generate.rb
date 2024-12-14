# frozen_string_literal: true

require 'English'
Puppet::Type.type(:krb5kdc_auto_keytabs).provide :generate do
  require 'fileutils'
  require 'puppet/util'

  desc <<~DESC
    Manage the auto-generated keytabs and principals on the KDC

    Note: This will *never* remove principals from your KDC but it will add
      them if necessary
  DESC

  commands kadmin: 'kadmin.local'

  def exists?
    require 'fileutils'
    require 'find'

    target_dir      = @resource[:name]
    target_realms   = @resource[:realms]
    target_realms ||= []
    global_services = @resource[:global_services]
    global_services ||= []
    global_services << 'host'
    global_services.uniq!
    host_hash = @resource[:hosts]
    host_hash ||= {}

    # No reason to do all the processing if we're just trying to delete things
    return File.directory?(target_dir) if resource[:ensure].to_s == 'absent'

    principal_list = execute(%(#{command(:kadmin)} -q "list_principals")).split.map(&:strip)

    # Extract all of the realms for which we are authoritative
    valid_realms = principal_list
                   .select { |x| x =~ %r{^K/M@} }
                   .map { |x| x.split('@').last }
                   .sort.uniq

    # Prep entries for anything we know about in a valid realm
    if @resource[:all_known]
      known_hostnames = principal_list.select { |x| x =~ %r{^host/} }.map do |princ|
        princ =~ %r{host/(.*)@}
        Regexp.last_match(1)
      end

      known_host_principals = []
      known_hostnames.each do |hname|
        known_host_principals += principal_list.select do |princ|
          princ =~ %r{^.+/#{hname}@}
        end
      end

      known_host_principals.each do |host|
        next unless host =~ %r{^(.*)/(.*)@(.*)}

        host_svc = Regexp.last_match(1)
        host_name = Regexp.last_match(2)
        host_realm = Regexp.last_match(3)

        next unless valid_realms.include?(host_realm)

        if host_hash[host_name]
          unless host_hash[host_name]['realms'].include?(host_realm)
            host_hash[host_name]['realms'] << host_realm
          end

          unless host_hash[host_name]['services'].include?(host_svc)
            host_hash[host_name]['services'] << host_svc
          end
        else
          host_hash[host_name] ||= {
            'ensure' => 'present',
            'realms' => Array(host_realm),
            'services' => (Array(host_svc) + global_services).uniq
          }
        end
      end
    end

    # Prep entries for anything we can introspect in a valid realm
    if @resource[:introspect]
      introspect_hosts.each do |host|
        next if host_hash.keys.include?(host)

        host_hash[host] = {
          'ensure' => 'present',
          'realms' => target_realms,
          'services' => global_services
        }
      end
    end

    # Might as well build these while we're trolling through
    @principals_to_process = {}
    @principals_to_remove = Dir.glob(File.join(target_dir, '*'))

    # Process ALL THE HOSTS
    host_hash.keys.sort.each do |hostname|
      host = host_hash[hostname].dup

      # If we've been told to add hosts to specific realms, we need to add them
      # to the array.
      host['realms'] += target_realms
      host['realms'].uniq!

      (host['realms'] - valid_realms).each do |realm|
        host['realms'].delete(realm)
      end

      host_dir = File.join(target_dir, hostname)

      host_keytab = File.join(host_dir, 'krb5.keytab')
      host_tmp_keytab = File.join(host_dir, '.krb5.keytab')

      @principals_to_remove.delete(host_dir)

      host_principals = []
      host['realms'].each do |realm|
        host['services'].each do |service|
          host_principals << %(#{service}/#{hostname}@#{realm})
        end
      end

      host_principals.each do |host_principal|
        # Do we need to update this principal?
        kvnos = nil
        principal_vnos = []
        kvno_file = File.join(host_dir, '.kvno')
        if File.exist?(kvno_file)
          kvnos = File.read(kvno_file).lines.grep(%r{^\d+$}).map(&:strip)
        end

        must_generate = true
        must_create = false
        if principal_list.include?(host_principal)
          principal_vnos = get_principal_vnos(host_principal)

          if kvnos && (principal_vnos.count == kvnos.count) && (kvnos - principal_vnos).empty?
            must_generate = false
          end
        else
          must_create = true
        end

        if must_generate || must_create
          @principals_to_process[host_principal] = {
            vno_file: kvno_file,
            vnos: principal_vnos,
            tmp_keytab: host_tmp_keytab,
            keytab: host_keytab
          }
        end
        if must_create
          @principals_to_process[host_principal][:create] = true
          @principals_to_process[host_principal][:generate] = true
        end

        if must_generate
          @principals_to_process[host_principal][:generate] = true
        end
      end
    end

    @principals_to_process.empty?
  end

  def sync_keytabs
    target_dir      = @resource[:name]
    user            = @resource[:user]
    group           = @resource[:group]

    FileUtils.mkdir_p(target_dir) unless File.directory?(target_dir)
    FileUtils.chmod(0o750, target_dir)
    FileUtils.chown(user, group, target_dir)

    @principals_to_process.keys.sort.each do |princ_name|
      princ = @principals_to_process[princ_name]

      host_dir = File.dirname(princ[:tmp_keytab])
      FileUtils.mkdir_p(host_dir) unless File.directory?(host_dir)
      FileUtils.chmod(0o750, host_dir)
      FileUtils.chown(user, group, host_dir)

      if princ[:create]
        cmd = %(#{command(:kadmin)} -q "add_principal -randkey +allow_renewable +allow_svr #{princ_name}")
        Puppet.debug("Running: #{cmd}")
        execute(cmd)
      end

      # We need to update the vnos array if we just generated a principal
      if princ[:vnos].empty?
        princ[:vnos] = get_principal_vnos(princ_name)
      end

      if princ[:generate]
        cmd = %(#{command(:kadmin)} -q "ktadd -norandkey -k #{princ[:tmp_keytab]} #{princ_name}")

        Puppet.debug("Running: #{cmd}")
        execute(cmd)
      end

      if $CHILD_STATUS.success?
        File.open(princ[:vno_file], 'w') do |fh|
          princ[:vnos].each do |vno|
            fh.puts(vno)
          end
        end
      else
        Puppet.warning("Could not add '#{princ_name}' to keytab at '#{princ[:keytab]}'")
        FileUtils.rm_f(princ[:tmp_keytab])
      end

      # This is some ugly foo to ensure the tmp .krb5.keytab file is written to
      # krb5.keytab once.
      FileUtils.mv(princ[:tmp_keytab], princ[:keytab]) if File.exist?(princ[:tmp_keytab])
      [princ[:keytab], princ[:vno_file]].each do |f|
        FileUtils.chmod(0o640, f)
        FileUtils.chown(user, group, f)
      end
    end

    clean_files(@principals_to_remove) if @resource[:purge]
  end

  def delete_keytabs
    clean_files(Dir.glob(File.join(@resource[:name], '*')))
  end

  private

  def get_principal_vnos(principal)
    principal_data = execute(%(#{command(:kadmin)} -q "get_principal #{principal}"))

    principal_data.lines.grep(%r{^\s*Key:\s+vno\s+\d+}m) do |str|
      str.match(%r{\d+})[0]
    end
  end

  def clean_files(files_to_remove)
    return true if files_to_remove.empty?

    files_to_remove.each do |file|
      # Be careful about cleaning up these directories!

      if File.directory?(file) && Dir.glob(File.join(file, '*')).empty?
        FileUtils.rmdir(file)
        next
      end

      Find.find(file) do |path|
        path.strip!

        next if path == '/'
        next if Dir.glob('/*').include?(path)

        # If we have a keytab, remove us
        if %r{keytab$}.match?(path)
          FileUtils.rm_rf(file)
          break
        end
      end
    end

    basedir = File.dirname(files_to_remove.first)
    if Dir.glob(File.join(basedir, '*')).empty?
      FileUtils.rmdir(basedir)
    else
      Puppet.error("Could not remove module directory '#{basedir}'")
    end
  end

  def introspect_hosts
    discovered_hosts = []

    search_paths = [
      'keydist',
      File.join(
        '/var',
        'simp',
        'environments',
        Puppet[:environment],
        'site_files',
        'pki_files',
        'files',
        'keydist',
      ),
    ]

    base_dirs = [Puppet[:confdir]]

    if Puppet[:environmentpath] && Puppet[:environment]
      env_paths = Puppet[:environmentpath].split(':')
      env_paths.map! { |x| File.join(x, Puppet[:environment]) }

      unless env_paths.empty?
        base_dirs = []

        env_paths.each do |env_path|
          if File.directory?(env_path)
            base_dirs << env_path
          end
        end
      end
    end

    found_base_dir = false
    base_dirs.each do |base_dir|
      if File.directory?(base_dir)
        found_base_dir = true
        break
      end
    end

    return discovered_hosts unless found_base_dir

    search_paths = search_paths.map { |path|
      path = if path[0].chr == '/'
               path
             else
               base_dirs.map { |x| File.join(x, path) }
             end
    }.flatten.compact

    search_paths.each do |path|
      if File.directory?(path)
        discovered_hosts += Dir.glob(File.join(path, '*.*')).map { |x| File.basename(x) }
      end
    end

    discovered_hosts.sort.uniq
  end
end
