require 'puppet/property/list'
require 'puppet/provider/parsedfile'

module Puppet
  newtype(:mounttab) do
    @doc = "Manages entries in the filesystem table."

    ensurable

    newproperty(:device) do
      desc "The device providing the mount.  This can be whatever
        device is supporting by the mount, including network
        devices or devices specified by UUID rather than device
        path, depending on the operating system."

      validate do |value|
        raise Puppet::Error, "device must not contain whitespace: #{value}" if value =~ /\s/
      end
    end

    newproperty(:blockdevice) do
      desc "The device to fsck.  This is property is only valid
        on Solaris, and in most cases will default to the correct
        value."

      defaultto do
        if Facter.value(:operatingsystem) == "Solaris"
          if device = @resource[:device] and device =~ %r{/dsk/}
            device.sub(%r{/dsk/}, "/rdsk/")
          elsif fstype = resource[:fstype] and fstype.downcase == 'nfs'
            '-'
          else
            nil
          end
        else
          nil
        end
      end

      validate do |value|
        raise Puppet::Error, "blockdevice must not contain whitespace: #{value}" if value =~ /\s/
      end

    end

    newproperty(:fstype) do
      desc "The mount type.  Valid values depend on the
        operating system.  This is a required option."

      validate do |value|
        raise Puppet::Error, "fstype must not contain whitespace: #{value}" if value =~ /\s/
      end
    end

    newproperty(:options, :parent => Puppet::Property::List) do
      desc "Mount options for the mount.  More than one option should
        be specified as an array"

      def delimiter
        ","
      end

      def inclusive?
        true
      end

      validate do |value|
        raise Puppet::Error, "multiple options have to be specified as an array not a comma separated list" if value =~ /,/
        raise Puppet::Error, "option must not contain whitespace: #{value}" if value =~ /\s/
      end

    end

    newproperty(:pass) do
      desc "The pass in which the mount is checked."

      defaultto do
        if resource.managed?
          if Facter.value(:operatingsystem) == 'Solaris'
            '-'
          else
            0
          end
        end
      end
    end

    newproperty(:atboot) do
      desc "Whether to mount the mount at boot.  Not all platforms
        support this."

      newvalues :yes, :no
      aliasvalue :true, :yes
      aliasvalue :false, :no
    end

    newproperty(:dump) do
      desc "Whether to dump the mount.  Not all platform support this.
        Valid values are `1` or `0`. or `2` on FreeBSD, Default is `0`."

      if Facter.value(:operatingsystem) == "FreeBSD"
        newvalue(%r{(0|1|2)})
      else
        newvalue(%r{(0|1)})
      end

      defaultto do
        0 if resource.managed?
      end

    end

    newproperty(:target) do
      desc "The file in which to store the mount table.  Only used by
        those providers that write to disk."

      defaultto do
        if @resource.class.defaultprovider.ancestors.include?(Puppet::Provider::ParsedFile)
          @resource.class.defaultprovider.default_target
        else
          nil
        end
      end
    end

    newparam(:name) do
      desc "The mount path for the mount."

      isnamevar

      validate do |value|
        raise Puppet::Error, "mount name must not contain whitespace: #{value}" if value =~ /\s/
        # Except of root / a trailing slash can cause problems
        raise Puppet::Error, "mount should be specified without a trailing slash: #{value}" if value =~ /.+\/$/
      end
    end

  end
end
