# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-krb5` manages the MIT Kerberos 5 stack on Enterprise Linux systems — both
the **client** side (installing `krb5-workstation`, writing `/etc/krb5.conf`)
and, optionally, the **KDC** server side (`krb5-server`, `kdc.conf`, realm
initialization, ACLs, keytab generation).

Its central design idea is an **include-directory config model**: rather than
templating a single monolithic `/etc/krb5.conf`, the module writes a small
`/etc/krb5.conf` whose only content is two `includedir` lines, and then drops
one file *per setting* into `/etc/krb5.conf.simp.d` (`manifests/config.pp`).
Each `[section]:key` pair becomes its own `…__setting` file created by the
`krb5::setting` define (`manifests/setting.pp`). The KDC side mirrors this
exactly for `kdc.conf` (`manifests/kdc/config.pp`). The SIMP-managed
directory is `purge => true, recurse => true`, so Puppet is authoritative over
its contents (`manifests/config.pp`).

The public entry class `krb5` just contains `krb5::install` then `krb5::config`
(`manifests/init.pp`); the client and KDC are opt-in classes/defines layered
on top.

### Business logic

- **`krb5` (`manifests/init.pp`)** — public base class. Consumers
  `include 'krb5'`. Parameters `$ldap`, `$firewall`, `$haveged` come from the
  `simp_options::*` seam; `$enctypes` defaults to
  `['aes256-cts-hmac-sha1-96', 'aes128-cts-hmac-sha1-96']` and is the source of
  the three `permitted_*_enctypes` config defaults. Calls
  `simplib::assert_metadata` (`init.pp`), then `contain`s install → config
  (`init.pp`).

- **`krb5::install` (`manifests/install.pp`, PRIVATE)** — installs
  `$packages` (from module data, default `['krb5-workstation']` —
  `data/common.yaml`) at `$ensure`. If `$haveged` (inherited from `krb5`),
  asserts the optional `simp/haveged` dependency and `include`s `haveged`
  (`install.pp`).

- **`krb5::config` (`manifests/config.pp`, PRIVATE, `inherits krb5`)** —
  writes the `/etc/krb5.conf` includedir stub, creates the two include dirs, and
  `include`s `krb5::config::default_settings`. Validates `$renew_lifetime` via
  the custom `krb5::validate_time_duration` function (`config.pp`). Note
  `$default_realm` defaults to `inline_template('<%= @domain.upcase %>')`
  (`config.pp`) and `$puppet_exclusive_managed` (`config.pp`) is a
  **documented-but-dead parameter** — it is declared and doc'd but never
  referenced in the body; the `.simp.d` dir is unconditionally purged.

- **`krb5::config::default_settings` (`manifests/config/default_settings.pp`,
  PRIVATE)** — emits one `krb5::setting` per libdefaults key, plus
  `krb5::setting::domain_realm` for each realm domain (`default_settings.pp`).

- **`krb5::setting` (`manifests/setting.pp`)** — the core define. Requires
  the name to match `^.+:.+$` i.e. `section:key` (`setting.pp`), splits it,
  munges it into a safe filename via `krb5::munge_conf_filename`
  (`setting.pp`), and writes `[section]\n  key = value\n`. Fails unless
  `Class['krb5']` is already declared (`setting.pp`).

- **`krb5::setting::domain_realm` (`manifests/setting/domain_realm.pp`)** and
  **`krb5::setting::realm` (`manifests/setting/realm.pp`)** — thin wrappers that
  emit `krb5::setting` / template-rendered files for `[domain_realm]` and
  `[realms]` blocks. `realm` renders `templates/realm.erb`.

- **`krb5::client` (`manifests/client.pp`)** — sets up a client against a
  KDC. If `$realms` is empty it derives a default realm from
  `simp_options::puppet::server` (falling back to the `servername` server fact)
  and **`fail`s if no KDC can be determined** (`client.pp`). It avoids
  redeclaring a realm the KDC class may already own (`client.pp`).

- **`krb5::keytab` (`manifests/keytab.pp`)** — distributes the system
  keytab from `puppet:///modules/krb5_files/keytabs/<fqdn>` into
  `/etc/krb5_keytabs`, then copies `krb5.keytab` into place. Depends on an
  out-of-tree `krb5_files` module for the source files.

- **`krb5::kdc` (`manifests/kdc.pp`, `inherits krb5`)** — the KDC
  orchestrator. Contains install/config/service and the EL7 SELinux hotfix.
  When `$auto_initialize` (default **true**) it declares a
  `krb5::kdc::realm` for `$auto_realm` (the node's networking domain) and, unless
  already declared, a matching `krb5::setting::realm`
  (`kdc.pp`). When `$auto_generate_host_keytabs` (default **true**) it
  includes `krb5::kdc::auto_keytabs` (`kdc.pp`). A collector forces all
  `Krb5::Setting` resources to notify the service (`kdc.pp`).

- **`krb5::kdc::config` (`manifests/kdc/config.pp`, PRIVATE)** — writes
  `kdc.conf` (includedir model), stores a **1024-char auto-generated password**
  from `simplib::passgen('kdb5kdc', …)` in a credential file with
  `replace => false` (`kdc/config.pp`), and runs
  `initialize_principal_database` — `kdb5_util create` guarded by
  `creates => …/principal` (`kdc/config.pp`). Also removes the stock
  `*/admin@EXAMPLE.COM` ACL via the custom `krb5_acl` type (`kdc/config.pp`).

- **`krb5::kdc::realm` (`manifests/kdc/realm.pp`)** — renders a realm
  block into `kdc.conf.simp.d` from `templates/kdc/realm.erb`. When
  `$initialize`, it creates the admin ACL and runs `kadmin.local` execs to add
  the admin principal and its keytab, each guarded by an idempotency
  `unless` (`kdc/realm.pp`). Validates `default_principal_flags` against
  a fixed allow-list (`kdc/realm.pp`).

- **`krb5::kdc::firewall` (`manifests/kdc/firewall.pp`, PRIVATE)** — asserts the
  optional `simp/iptables` dependency and opens KDC/kadmind ports
  (`firewall.pp`).

- **`krb5::kdc::selinux_hotfix` (`manifests/kdc/selinux_hotfix.pp`, PRIVATE)** —
  only active when SELinux is enabled; asserts the optional `vox_selinux`
  dependency and installs a `.te` policy module built from
  `templates/selinux/krb5kdc_hotfix.te.epp` (`selinux_hotfix.pp`).

- **`krb5::kdc::service` / `krb5::kdc::install`** — manage the `krb5kdc` +
  `kadmin` services and the `krb5-server` (+ `krb5-server-ldap` when `$ldap`)
  packages.

### Custom Puppet types, providers, and functions (`lib/`)

- **`krb5_acl` type + `manage_entry` provider**
  (`lib/puppet/type/krb5_acl.rb`, `lib/puppet/provider/krb5_acl/manage_entry.rb`)
  — manages `kadmind` ACL file entries per `kadmind(8)`. The type does custom
  duplicate-declaration detection in `initialize` (`krb5_acl.rb`),
  upcases realms, and `autonotify`s the `kadmin` service (`krb5_acl.rb`).
  Mask semantics are inverted-case: lowercase activates, uppercase deactivates
  (`krb5_acl.rb`).

- **`krb5kdc_auto_keytabs` type + `generate` provider**
  (`lib/puppet/type/krb5kdc_auto_keytabs.rb`,
  `lib/puppet/provider/krb5kdc_auto_keytabs/generate.rb`) — introspects the KDC
  (`kadmin.local list_principals`) and generates/collects host keytabs into an
  output directory, optionally publishing them into the Puppet environment's
  `site_files/krb5_files`. The `__default__` namevar resolves to either the
  environment `site_files` path or `/var/kerberos/krb5kdc/generated_keytabs`
  (`krb5kdc_auto_keytabs.rb`).

- **`krb5::munge_conf_filename`** (`lib/puppet/functions/krb5/munge_conf_filename.rb`)
  — sanitizes a `section:key` string into a filename (`[A-Za-z0-9_-]`, other
  chars → `-`, leading `-` → `_`). Used by every setting/realm define.

- **`krb5::validate_time_duration`** (`lib/puppet/functions/krb5/validate_time_duration.rb`)
  — validates krb5 time-duration strings (`Nd Nh Nm Ns`, `H:M:S`, or bare
  seconds) and fails if invalid or > 2147483647s.

### Gotchas / non-obvious details

- **The config model is include-directory, not monolithic.** Never template a
  full `krb5.conf`. Add settings as `krb5::setting { 'section:key': … }`; they
  land as individual purge-managed files in `/etc/krb5.conf.simp.d`
  (`config.pp`, `setting.pp`).
- **`krb5::kdc` auto-initializes by default.** `$auto_initialize` and
  `$auto_generate_host_keytabs` both default to `true` (`kdc.pp`), so
  including `krb5::kdc` with no params will build a realm from the node's
  networking domain, initialize the principal DB, and try to generate host
  keytabs. This is a lot of implicit behavior — know it before including the class.
- **The KDC master password is machine-generated and sticky.** It comes from
  `simplib::passgen` and is written with `replace => false`; the principal DB is
  only built when `…/principal` is absent (`kdc/config.pp`). Changing
  the password param has **no effect** unless the credential file is physically
  removed — documented at `kdc/config.pp`.
- **`krb5::config::puppet_exclusive_managed` is a dead parameter.** It is
  declared and documented (`config.pp`) but never used; the `.simp.d`
  directory is always purged. Do not assume setting it changes anything.
- **`krb5::setting` and its wrappers `fail` if `krb5` isn't included first**
  (`setting.pp`, `setting/domain_realm.pp`,
  `setting/realm.pp`); `krb5::kdc::realm` likewise requires `krb5::kdc`
  (`kdc/realm.pp`).
- **`krb5::keytab` needs an external `krb5_files` module.** The keytab source is
  `puppet:///modules/krb5_files/…` (`keytab.pp`) — not shipped here.
- **The SELinux hotfix targets EL7** (`selinux_hotfix.pp` header) but the EPP
  template's branching (`krb5kdc_hotfix.te.epp`) adds extra rules for
  RedHat/Amazon > 7/2 — it runs whenever SELinux is enabled, not only EL7.
- **Known latent bugs in `lib/` (left as-is, pre-existing):**
  - `krb5_acl` provider `mod_target`: in the `operation_target != 'undef'`
    branch, `new_rule` references itself before assignment
    (`manage_entry.rb`).
  - `krb5kdc_auto_keytabs` type: `group` param `defaultto('group')` — a literal
    string `'group'`, almost certainly meant to be `'root'`/`Puppet[:group]`
    (`krb5kdc_auto_keytabs.rb`); and `realms` validation uses
    `is_string($_default_principal_flags)` / `is_string` idioms in
    `kdc/realm.pp` referencing an undefined var. Don't "fix" these as part
    of an unrelated change without confirming intent.

## The `simp_options` / `simplib::lookup` seam

This is the module's SIMP feature-toggle seam. All calls use
`simplib::lookup('<key>', { 'default_value' => … })`:

| Location | Key | `default_value` |
|----------|-----|-----------------|
| `init.pp` | `simp_options::ldap` | `false` |
| `init.pp` | `simp_options::firewall` | `false` |
| `init.pp` | `simp_options::haveged` | `true` |
| `install.pp` | `simp_options::package_ensure` | `'installed'` |
| `kdc/install.pp` | `simp_options::package_ensure` | `'installed'` |
| `kdc.pp` | `simp_options::trusted_nets` | `['127.0.0.1', '::1']` |
| `kdc/realm.pp` | `simp_options::trusted_nets` | `['127.0.0.1']` |
| `client.pp` | `simp_options::puppet::server` | `servername` server fact / `undef` |
| `kdc/auto_keytabs.pp` | `krb5::kdc::auto_realm` | node networking domain |
| `kdc/realm.pp` | `krb5::kdc::config_dir` | `/var/kerberos/krb5kdc/kdc.conf.simp.d` |
| `kdc/realm.pp` | `krb5::kdc::firewall` | `false` |

**`simp/simp_options` is NOT a declared dependency** in `metadata.json`, yet the
manifests consume the `simp_options::*` keys above via `simplib::lookup`
(the function comes from `simp/simplib`). `simp_options` appears only as a test
fixture (`.fixtures.yml`). Keep routing SIMP toggles through
`simplib::lookup('simp_options::*', { 'default_value' => … })` with an explicit
default rather than assuming `simp_options` is included.

## Dependencies

Hard dependencies (from `metadata.json`):

- `simp/simplib` `>= 4.9.0 < 6.0.0` (provides `simplib::lookup`,
  `simplib::assert_metadata`, `simplib::assert_optional_dependency`,
  `simplib::passgen`, `simplib::validate_re_array`, and the `Simplib::Host`,
  `Simplib::Netlist`, `Simplib::Port` types)
- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0`

Optional dependencies (from `metadata.json` `simp.optional_dependencies`,
each asserted at runtime with `simplib::assert_optional_dependency` behind a
condition):

- `simp/haveged` `>= 0.4.5 < 1.0.0` — when `$haveged` (`install.pp`)
- `simp/iptables` `>= 6.5.3 < 9.0.0` — when the KDC firewall is on
  (`kdc/firewall.pp`)
- `simp/vox_selinux` (no version pin) — when SELinux is enabled
  (`kdc/selinux_hotfix.pp`)

Fixture-only dependencies (from `.fixtures.yml`, for test compilation only —
not runtime deps): `augeas_core`, `firewalld`, `selinux`, `selinux_core`,
`simp_firewalld`, `simp_options`, `systemd`, plus the hard/optional deps above.

Runtime requirement (from `metadata.json` `requirements`): `openvox
>= 8.0.0 < 9.0.0`.

Supported OS matrix (from `metadata.json`): CentOS 9/10; RedHat 8/9/10;
OracleLinux 8/9/10; Rocky 8/9/10; AlmaLinux 8/9/10.

## Repository layout

- `manifests/init.pp` — public `krb5` base class (install → config).
- `manifests/{install,config}.pp`, `manifests/config/default_settings.pp` —
  private client install/config plumbing.
- `manifests/{client,keytab}.pp` — public client and keytab-distribution classes.
- `manifests/setting.pp`, `manifests/setting/{realm,domain_realm}.pp` — the
  `krb5::setting*` defines that write per-setting config files.
- `manifests/kdc.pp` + `manifests/kdc/*.pp` — the KDC server subsystem
  (install, config, service, firewall, selinux_hotfix, auto_keytabs, realm).
- `data/common.yaml` — module data: `krb5::install::packages: [krb5-workstation]`
  with a deep-merge `lookup_options` knockout config. No `data/os/` overrides
  exist despite the OS/Kernel tiers in `hiera.yaml`.
- `hiera.yaml` — v5 hierarchy: OS+release → OS → Kernel → common.
- `templates/realm.erb`, `templates/kdc/realm.erb` — ERB realm blocks;
  `templates/selinux/krb5kdc_hotfix.te.epp` — EPP SELinux policy.
- `lib/puppet/type/`, `lib/puppet/provider/`, `lib/puppet/functions/krb5/` —
  the custom `krb5_acl` and `krb5kdc_auto_keytabs` types/providers and the two
  `krb5::*` functions (see above).
- `spec/classes/`, `spec/defines/`, `spec/functions/`, `spec/unit/puppet/` —
  rspec-puppet and rspec-Ruby unit tests.
- `spec/acceptance/suites/default/{00_base,01_autokeys}_spec.rb` — beaker
  acceptance suite; nodesets under `spec/acceptance/nodesets/` (the `docker_*`
  set used by CI, plus vagrant alma/centos/oel/rhel/rocky 8/9/10).
- `REFERENCE.md` — generated Puppet Strings reference.
- **Acceptance runs in CI:** `.github/workflows/pr_tests.yml` has an
  `acceptance` job whose matrix of docker nodesets (alma8/9/10, centos9/10,
  oel8/9/10, rocky8/9/10) runs `bundle exec rake beaker:suites[default,<node>]`
  under `BEAKER_HYPERVISOR=docker` (`pr_tests.yml`).

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Run one spec file
bundle exec rspec spec/classes/init_spec.rb

# Puppet lint + metadata lint
bundle exec rake lint
bundle exec rake metadata_lint

# Puppet syntax
bundle exec rake syntax

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run a beaker acceptance suite (as CI does)
bundle exec rake beaker:suites[default,docker_alma9]
```

Relevant gem pins (from `Gemfile`): `puppetlabs_spec_helper ~> 8.0.0`,
`simp-rake-helpers ~> 5.24.0`, `simp-rspec-puppet-facts ~> 4.0.0`,
`simp-beaker-helpers ~> 2.0.0`, `rubocop ~> 1.88.0`. The Gemfile loads **both**
the `openvox` and `puppet` gems during the migration; the tested version range
defaults to `>= 8 < 9` (`Gemfile`).

## Conventions

- Preserve the `@summary` / `@param` / `@attr` puppet-strings docstrings on
  classes and defines — they drive `REFERENCE.md`. Regenerate `REFERENCE.md`
  after changing docs or parameters.
- Add new krb5.conf/kdc.conf settings via `krb5::setting` (and the realm/
  domain_realm wrappers), not by templating whole config files — respect the
  includedir model.
- Keep the package list in module data (`data/common.yaml`), not hard-coded in
  the manifest.
- Route SIMP feature toggles through
  `simplib::lookup('simp_options::*', { 'default_value' => … })` with an
  explicit default.
- Guard optional integrations (`haveged`, `iptables`, `vox_selinux`) with
  `simplib::assert_optional_dependency` plus a condition — don't hard-`include`
  optional modules.
- Mark internal classes `assert_private()` (as install/config/kdc subclasses
  do); keep only `krb5`, `krb5::client`, `krb5::keytab`, `krb5::kdc`, and the
  `krb5::setting*` / `krb5::kdc::realm` defines as public API.
- `Gemfile`, `.gitignore`, `.pdkignore`, and `.github/workflows/*` carry a
  **puppetsync** notice — they are baseline-managed and the next sync overwrites
  local edits. Push changes to those files upstream to the baseline, not here.
- Match the existing 2-space Puppet indentation and aligned-arrow parameter
  style used across `manifests/`.
