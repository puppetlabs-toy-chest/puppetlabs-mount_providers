#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/provider/mountpoint/linux'

describe Puppet::Type.type(:mountpoint).provider(:linux) do
  let(:resource) do
    Puppet::Type.type(:mountpoint).new(
      :ensure   => :present,
      :name     => "/mountdir",
      :device   => "/device",
      :provider => :linux
    )
  end

  let(:provider) do
    described_class.new(resource)
  end

  before :each do
    described_class.expects(:execute).never
    described_class.stubs(:suitable?).returns(true)
  end

  describe "#handle_notification" do
    it "handles refresh events sent to the type" do
      resource.provider.expects(:handle_notification).once
      resource.refresh
    end
  end

  describe "#exists?" do
    it "should be present if it is included in mount output" do
      provider.stubs(:mount).returns <<-MOUNT_OUTPUT.gsub(/^\s+/, '')
        /dev/mapper/VolGroup00-LogVol00 on / type ext3 (rw)
        proc on /proc type proc (rw)
        sysfs on /sys type sysfs (rw)
        devpts on /dev/pts type devpts (rw,gid=5,mode=620)
        /dev/cciss/c0d0p1 on /boot type ext3 (rw)
        tmpfs on /dev/shm type tmpfs (rw)
        none on /proc/sys/fs/binfmt_misc type binfmt_misc (rw)
        /device on /mountdir type ext3 (rw)
      MOUNT_OUTPUT

      provider.should be_exists
    end

    it "should be absent if it is missing from mount output" do
      provider.stubs(:mount).returns <<-MOUNT_OUTPUT.gsub(/^\s+/, '')
        /dev/mapper/VolGroup00-LogVol00 on / type ext3 (rw)
        proc on /proc type proc (rw)
        sysfs on /sys type sysfs (rw)
        devpts on /dev/pts type devpts (rw,gid=5,mode=620)
        /dev/cciss/c0d0p1 on /boot type ext3 (rw)
        tmpfs on /dev/shm type tmpfs (rw)
        none on /proc/sys/fs/binfmt_misc type binfmt_misc (rw)
      MOUNT_OUTPUT

      provider.should_not be_exists
    end

    it "should be present if it is included in mount output with an incorrect device" do
      provider.stubs(:mount).returns <<-MOUNT_OUTPUT.gsub(/^\s+/, '')
        /dev/mapper/VolGroup00-LogVol00 on / type ext3 (rw)
        proc on /proc type proc (rw)
        sysfs on /sys type sysfs (rw)
        devpts on /dev/pts type devpts (rw,gid=5,mode=620)
        /dev/cciss/c0d0p1 on /boot type ext3 (rw)
        tmpfs on /dev/shm type tmpfs (rw)
        none on /proc/sys/fs/binfmt_misc type binfmt_misc (rw)
        /wrongdevice on /mountdir type ext3 (rw)
      MOUNT_OUTPUT

      provider.should be_exists
    end
  end
end
