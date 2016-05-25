Puppet::Type.type(:krb5_acl).provide :manage_entry do
  require 'fileutils'
  require 'puppet/util'

  desc "Provider for managing krb5 ACL files."

  KRB5_ACL_EDIT_MSG = "# This file is managed by Puppet but may be carefully edited manually."

  def mod_target(mod_type)
      # Original Content
      old_acl = []

      operation_mask = Array(@resource[:operation_mask]).flatten.join

      if @resource[:operation_target] == 'undef'
        new_rule = "#{@resource[:principal]} #{operation_mask}"
      else
        new_rule = "#{new_rule} #{@resource[:operation_target]}"
      end

      begin
        File.open(@resource[:target],'r'){ |fh| old_acl = fh.read.split("\n") }
      rescue =>  detail
        debug("Original ACL file '#{@resource[:target]}' not found, creating.")
      end

      new_acl = []

      # Add a new entry, preserving all existing entries.
      if mod_type.eql?("create")
        new_acl << new_rule

      # Modify an existing entry (if it exists).
      # If there's an operation target, match on that.
      elsif mod_type.eql?("modify")
        old_acl.each do |acl|
          principal,mask,target = acl.strip.split(/\s+/)

          if principal == @resource[:principal]
            if !target || (target == @resource[:operation_target])
              new_acl << new_rule
              next
            end
          end

          new_acl << acl
        end

      # Remove an entry
      elsif mod_type.eql?("delete")
        new_acl = old_acl.dup

        to_delete = []
        new_acl.each_index { |i|
          principal,mask,target = new_acl[i].strip.split(/\s+/)

          if principal == @resource[:principal]
            if !target ||
               (target =~ Regexp.new(@resource[:operation_target])) ||
               ( (new_acl[i-1] =~ /^\s+#/) && (new_acl[i-1] !~ KRB5_ACL_EDIT_MSG) )

              to_delete << i
            end
          end
        }

        to_delete.each do |del_i|
          new_acl.delete_at(del_i)
        end
      end

      new_acl.insert(0,KRB5_ACL_EDIT_MSG) unless new_acl.include?(KRB5_ACL_EDIT_MSG)
      File.open(@resource[:target],'w') { |f| f.puts(new_acl.join("\n")) }
      File.chmod(0600,@resource[:target])
  end

  def create
    mod_target("create")
  end

  def destroy
    mod_target("delete")
  end

  def exists?
    acl_file = []
    begin
      File.open(@resource[:target],'r'){ |fh| acl_file = fh.read.split("\n") }
    rescue
      return false
    end

    acl_file.each do |x|
      principal,mask,target = x.strip.split(/\s+/)

      if principal == @resource[:principal]
        if !target || (target =~ Regexp.new(@resource[:operation_target]))
          return true
        end
      end
    end

    return false
  end

  def operation_mask
    acl_file = []
    if File.readable?(@resource[:target])
      File.open(@resource[:target],'r'){ |fh| acl_file = fh.read.split("\n") }
    end

    acl_file.each do |acl|
      principal,mask,target = acl.strip.split(/\s+/)

      if principal == @resource[:principal]
        if !target || (target == @resource[:operation_target])
          return mask
        end
      end
    end

    fail Puppet::Error, "Did not find mask for #{@resource[:principal]}"
  end

  def operation_mask=(should)
    mod_target("modify")
    return nil
  end

end
