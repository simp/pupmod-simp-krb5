# frozen_string_literal: true

require 'beaker-rspec'
require 'tmpdir'
require 'yaml'
require 'simp/beaker_helpers'
include Simp::BeakerHelpers

unless ENV['BEAKER_provision'] == 'no'
  hosts.each do |host|
    # Install Puppet
    if host.is_pe?
      install_pe
    else
      install_puppet
    end
  end
end

RSpec.configure do |c|
  # ensure that environment OS is ready on each host
  fix_errata_on hosts

  # Detect cases in which no examples are executed (e.g., nodeset does not
  # have hosts with required roles)
  c.fail_if_no_examples = true

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install modules and dependencies from spec/fixtures/modules
    copy_fixture_modules_to(hosts)
    begin
      server = only_host_with_role(hosts, 'server')
    rescue ArgumentError => e
      server = only_host_with_role(hosts, 'default')
    end

    # Generate and install PKI certificates on each SUT
    Dir.mktmpdir do |cert_dir|
      run_fake_pki_ca_on(server, hosts, cert_dir)
      hosts.each { |sut| copy_pki_to(sut, cert_dir, '/etc/pki/simp-testing') }
    end

    # add PKI keys
    copy_keydist_to(server)

    # The optional `haveged` daemon is unnecessary on EL9+: those kernels ship
    # an always-seeded CRNG (jitterentropy) so /dev/random never blocks. On top
    # of that, the EL9+ haveged.service unit is hardened with seccomp
    # (SystemCallFilter), RestrictNamespaces, and MemoryDenyWriteExecute
    # directives that the daemon cannot satisfy inside the nested,
    # non-privileged container kernel used by GitHub Actions. The result is that
    # haveged starts and is immediately killed, so Service[haveged] never stays
    # `running` and the krb5 catalog is reported as non-idempotent on every
    # second apply (EL8 is unaffected because its haveged unit is not hardened).
    #
    # krb5 itself does not require haveged for any of its functionality, so we
    # disable the optional dependency on EL9+ where it provides no value and is
    # broken-in-container. EL8 continues to exercise the krb5 -> haveged path.
    #
    # This is written to the per-node hiera layer (`data/nodes/<certname>.yaml`)
    # rather than via `set_hieradata_on`, because that helper overwrites
    # `data/common.yaml` on every call. Individual examples (e.g. the autokeys
    # suite) set their own `common.yaml` data, which would otherwise clobber this
    # setting. The per-node layer is both clobber-proof and higher priority than
    # `common.yaml` in the default beaker hiera.yaml.
    hosts.each do |sut|
      next unless sut['platform'] =~ %r{el-(\d+)} && Regexp.last_match(1).to_i >= 9

      codedir = on(sut, 'puppet config print codedir').stdout.strip
      certname = fact_on(sut, 'networking.fqdn')
      node_hiera = "#{codedir}/environments/production/data/nodes/#{certname}.yaml"
      sut.mkdir_p(File.dirname(node_hiera))
      create_remote_file(sut, node_hiera, { 'simp_options::haveged' => false }.to_yaml)
    end
  rescue StandardError, ScriptError => e
    raise e unless ENV['PRY']

    # rubocop:disable Lint/Debugger
    require 'pry'
    binding.pry
    # rubocop:enable Lint/Debugger
  end
end
