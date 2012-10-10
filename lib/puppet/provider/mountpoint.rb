class Puppet::Provider::Mountpoint < Puppet::Provider
  def exists?
    ! entry[:name].nil?
  end

  def create
    mount_with_options(resource[:device], resource[:name])
  end

  def destroy
    unmount(resource[:name])
  end

  def device
    entry[:device]
  end

  def device=(value)
    unmount(resource[:name])
    mount_with_options(resource[:device], resource[:name])
  end

  def handle_notification
    remount if resource[:ensure] == :present and exists?
  end

  private

  def mount_with_options(*args)
    options = []
    if resource[:options] && resource[:options] != :absent
      options << '-o'
      options << (resource[:options].is_a?(Array) ?  resource[:options].join(',') : resource[:options])
    end

    mount(*(options + args.compact))
  end

  def entry
    raise Puppet::DevError, "Mountpoint entry method must be overridden by the provider"
  end

  def remount
    if resource[:remounts] == :true
      mount_with_options "-o", "remount", resource[:name]
    else
      unmount(resource[:name])
      mount_with_options(resource[:device], resource[:name])
    end
  end
end
