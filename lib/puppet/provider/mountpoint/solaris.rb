require 'puppet/type'

[ 'type', 'provider' ].each do |path|
  begin
    require "puppet/#{path}/mountpoint"
  rescue LoadError => detail
    require 'pathname' # JJM WORK_AROUND #14073 and #7788
    require Pathname.new(__FILE__).dirname + "../../../" + "puppet/#{path}/mountpoint"
  end
end

Puppet::Type.type(:mountpoint).provide(:solaris, :parent => Puppet::Provider::Mountpoint) do
  commands :mount => "mount", :unmount => "umount"

  confine :operatingsystem => :solaris
  defaultfor :operatingsystem => :solaris

  private

  def entry
    line = mount.split("\n").find do |line|
      File.expand_path(line.split.first) == File.expand_path(resource[:name])
    end
    line =~ /^(\S*) on (\S*)(?: (\S+))?/
    {:name => $1, :device => $2, :options => $3}
  end
end
