module Puppet
  newtype(:mountpoint) do
    feature :refreshable, "The provider can remount the filesystem.",
      :methods => [:remount]

    ensurable

    newproperty(:device) do
      desc "The device providing the mount.  This can be whatever
        device is supporting by the mount, including network
        devices or devices specified by UUID rather than device
        path, depending on the operating system."
    end

    newparam(:name, :namevar => true) do
      desc "The path to the mount point."
    end

    newparam(:options) do
      desc "Mount options for the mounts, as they would
        appear in the fstab."
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
  end
end
