Puppet::Type.type(:krb5_acl).provide :manage_entry do
  require 'fileutils'
  require 'puppet/util'

  desc "Provider for managing krb5 ACL files."

  @@edit_msg = "# This file is managed by Puppet but may be carefully edited manually."

  def mod_target(mod_type)
      # Original Content
      old_acl = []

      begin
        File.open(@resource[:target],'r'){ |fh| old_acl = fh.read.split("\n") }
      rescue =>  detail
        debug("Original ACL file '#{@resource[:target]}' not found, creating.")
      end

      new_acl = []

      # Add a new entry, preserving all existing entries.
      if mod_type.eql?("create")

        new_acl = new_acl + old_acl
        new_acl << "#{@resource[:principal]} #{@resource[:operation_mask]}"
        if @resource[:operation_target] != 'undef' then
          new_acl[-1] = "# #{@resource[:name]}\n#{new_acl[-1]} #{@resource[:operation_target]}"
        end

      # Modify an existing entry (if it exists).
      # If there's an operation target, match on that.
      elsif mod_type.eql?("modify")
        replaced_acl = false
        comment_at = nil
        old_acl.each do |acl|

          principal,mask,target = acl.strip.split(/\s+/)

          if principal == @resource[:principal] then
            if !target or target == @resource[:operation_target] then
              if new_acl[-1] =~ /^\s+#/ then
                # Found the comment
                comment_at = new_acl.length - 1
              end
              new_acl << acl
              replaced_acl = true
              next
            end
          end

          new_acl << acl
        end

        new_acl[comment_at] = "# #{@resource[:name]}"

      # Remove an entry
      elsif mod_type.eql?("delete")
        new_acl = old_acl.dup

        to_delete = []
        new_acl.each_index { |i|
          principal,mask,target = new_acl[i].strip.split(/\s+/)

          if principal == @resource[:principal] then
            if !target or
               target =~ Regexp.new(@resource[:operation_target]) or
               ( new_acl[i-1] =~ /^\s+#/ and new_acl[i-1] !~ @@edit_msg )
            then
              to_delete << i
            end
          end
        }

        to_delete.each do |del_i|
          new_acl.delete_at(del_i)
        end
      end

      not new_acl.include?(@@edit_msg) and new_acl.insert(0,@@edit_msg)

      File.open(@resource[:target],'w') { |f| f.puts(new_acl.join("\n")) }
      File.chmod(0600,@resource[:target])
  end

  def create
    mod_target("create")
  end

  def destroy
    mod_target("delete")
  end

  def passwd_sync
    mod_target("modify")  
    return nil
  end

  def exists?
    acl_file = []
    begin
      File.open(@resource[:target],'r'){ |fh| acl_file = fh.read.split("\n") }
    rescue =>  detail
      return false
    end

    acl_file.each do |x|
      principal,mask,target = x.strip.split(/\s+/)

      match = false
      if principal == @resource[:principal] then
        if !target or target =~ Regexp.new(@resource[:operation_target])
          return true
        end
      end
    end

    return false
  end

  def get_mask
    acl_file = []
    if File.readable?(@resource[:target]) then
      File.open(@resource[:target],'r'){ |fh| acl_file = fh.read.split("\n") }
    end

    acl_file.each do |acl|
      principal,mask,target = acl.strip.split(/\s+/)

      if principal == @resource[:principal] then
        if !target or target == @resource[:operation_target] then
          return mask
        end
      end
    end

    fail Puppet::Error, "Did not find mask for #{@resource[:principal]}"
  end
end
