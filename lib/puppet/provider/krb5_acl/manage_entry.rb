# frozen_string_literal: true

Puppet::Type.type(:krb5_acl).provide :manage_entry do
  require 'fileutils'
  require 'puppet/util'

  desc 'Provider for managing krb5 ACL files'

  @krb5_acl_edit_msg = '# This file is managed by Puppet but may be carefully edited manually'

  def mod_target(mod_type)
    # Original Content
    old_acl = []

    operation_mask = Array(@resource[:operation_mask]).join

    new_rule = if @resource[:operation_target] == 'undef'
                 "#{@resource[:principal]} #{operation_mask}"
               else
                 "#{new_rule} #{@resource[:operation_target]}"
               end

    begin
      File.open(@resource[:target], 'r') { |fh| old_acl = fh.read.split("\n") }
    rescue StandardError
      debug("Original ACL file '#{@resource[:target]}' not found, creating.")
    end

    new_acl = []

    # Add a new entry, preserving all existing entries.
    case mod_type
    when 'create'
      new_acl << new_rule

    # Modify an existing entry (if it exists).
    # If there's an operation target, match on that.
    when 'modify'
      old_acl.each do |acl|
        principal, _mask, target = acl.strip.split(%r{\s+})

        if principal == @resource[:principal] && (!target || (target == @resource[:operation_target]))
          new_acl << new_rule
          next
        end

        new_acl << acl
      end

    # Remove an entry
    when 'delete'
      new_acl = old_acl.dup

      to_delete = []
      new_acl.each_index do |i|
        principal, _mask, target = new_acl[i].strip.split(%r{\s+})

        next unless principal == @resource[:principal] && (!target ||
             (target =~ Regexp.new(@resource[:operation_target])) ||
             ((new_acl[i - 1] =~ %r{^\s+#}) && (new_acl[i - 1] !~ @krb5_acl_edit_msg)))

        to_delete << i
      end

      to_delete.each do |del_i|
        new_acl.delete_at(del_i)
      end
    end

    new_acl.insert(0, @krb5_acl_edit_msg) unless new_acl.include?(@krb5_acl_edit_msg)
    File.open(@resource[:target], 'w') { |f| f.puts(new_acl.join("\n")) }
    File.chmod(0o600, @resource[:target])
  end

  def create
    mod_target('create')
  end

  def destroy
    mod_target('delete')
  end

  def exists?
    acl_file = []
    begin
      File.open(@resource[:target], 'r') { |fh| acl_file = fh.read.split("\n") }
    rescue StandardError
      return false
    end

    acl_file.each do |x|
      principal, _mask, target = x.strip.split(%r{\s+})

      if principal == @resource[:principal] && (!target || (target =~ Regexp.new(@resource[:operation_target])))
        return true
      end
    end

    false
  end

  def operation_mask
    acl_file = []
    if File.readable?(@resource[:target])
      File.open(@resource[:target], 'r') { |fh| acl_file = fh.read.split("\n") }
    end

    acl_file.each do |acl|
      principal, mask, target = acl.strip.split(%r{\s+})

      if principal == @resource[:principal] && (!target || (target == @resource[:operation_target]))
        return mask
      end
    end

    raise Puppet::Error, "Did not find mask for #{@resource[:principal]}"
  end

  def operation_mask=(_should)
    mod_target('modify')
    # rubocop:disable Lint/Void
    nil
    # rubocop:enable Lint/Void
  end
end
