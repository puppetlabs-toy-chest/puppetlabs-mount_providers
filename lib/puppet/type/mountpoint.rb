Puppet::Type.newtype(:mountpoint) do
  @doc = "Manages currently mounted volumes, i.e. the live state of the filesystem.
See the discussion under the mounttab type for usage."

  feature :refreshable, "The provider can remount the filesystem.",
    :methods => [:remount]

  ensurable do
    newvalue(:present, :invalidate_refreshes => true) do
      unless provider.exists?
        provider.create
      end
    end

    newvalue(:absent) do
      if provider.exists?
        provider.destroy
      end
    end
  end

  newproperty(:device) do
    desc "The device providing the mount.  This can be whatever
      device is supporting by the mount, including network
      devices or devices specified by UUID rather than device
      path, depending on the operating system.  If you already have an entry
      in your fstab (or you use the mounttab type to create such an entry),
      it is generally not necessary to specify the fstype explicitly"

    validate do |value|
      raise Puppet::Error, "device is not allowed to contain whitespace" if value =~ /\s/
    end
  end

  newproperty(:fstype) do
    desc "The mount type.  Valid values depend on the
      operating system.  If you already have an entry in your fstab (or you use
      the mounttab type to create such an entry), it is generally not necessary to
      specify the fstype explicitly"

    validate do |value|
      raise Puppet::Error, "fstype is not allowed to contain whitespaces" if value =~ /\s/
    end
  end

  newparam(:name, :namevar => true) do
    desc "The path to the mount point."

    validate do |value|
      raise Puppet::Error, "name is not allowed to contain whitespace" if value =~ /\s/
      raise Puppet::Error, "name is not allowed to have trailing slashes" if value =~ %r{/$}
      raise Puppet::Error, "name must be an absolute path" if value =~ %r{^[^/]} or value =~ %r{/\.\./}
    end
  end

  newparam(:options) do
    desc "Mount options for the mounts, as they would
      appear in the fstab."

    validate do |value|
      value = [value] unless value.is_a? Array
      found_whitespace = false

      value.each do |option|
        found_whitespace = true if option =~ /\s/
      end

      raise Puppet::Error, "options cannot contain any spaces" if found_whitespace
    end
  end

  newparam(:remounts) do
    desc "Whether the mount can be remounted  `mount -o remount`.  If
      this is false, then the filesystem will be unmounted and remounted
      manually, which is prone to failure."

    newvalues(true, false)
    defaultto do
      case Facter.value(:operatingsystem)
      when "FreeBSD", "Darwin", "AIX"
        false
      else
        true
      end
    end
  end

  def refresh
    provider.handle_notification
  end
end
