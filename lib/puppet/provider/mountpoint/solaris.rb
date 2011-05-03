require 'puppet/type/mountpoint'
require 'puppet/provider/mountpoint'

Puppet::Type.type(:mountpoint).provide(:solaris, :parent => Puppet::Provider::Mountpoint) do
  commands :mount => "mount", :unmount => "umount"

  confine :operatingsystem => :solaris

  private

  def entry
    line = mount.split("\n").find do |line|
      File.expand_path(line.split.first) == File.expand_path(resource[:name])
    end
    line =~ /^(\S+) on (\S+)/
    {:name => $1, :device => $2}
  end
end
