require 'puppet/type/mountpoint'
require 'puppet/provider/mountpoint'

Puppet::Type.type(:mountpoint).provide(:linux, :parent => Puppet::Provider::Mountpoint) do
  commands :mount => "mount", :unmount => "umount"

  confine :kernel => :linux
  defaultfor :kernel => :linux

  private

  def entry
    line = mount.split("\n").find do |line|
      File.expand_path(line.split[2]) == File.expand_path(resource[:name])
    end
    line =~ /^(\S*) on (\S*) type (\S*) (?:\((\S+)\))?/
    {:device => $1, :name => $2, :options => $4}
  end
end
