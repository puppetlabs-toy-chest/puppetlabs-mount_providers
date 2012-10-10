#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/provider/mountpoint/solaris'

describe Puppet::Type.type(:mountpoint).provider(:solaris) do
  let(:resource) do
    Puppet::Type.type(:mountpoint).new(
      :ensure   => :present,
      :name     => "/mountdir",
      :device   => "/device",
      :provider => :solaris
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
        / on rpool/ROOT/opensolaris read/write/setuid/devices/dev=2d90002 on Wed Dec 31 16:00:00 1969
        /dev on /dev read/write/setuid/devices/dev=4a40000 on Mon May  2 10:41:43 2011
        /proc on proc read/write/setuid/devices/dev=4b00000 on Mon May  2 10:41:43 2011
        /mountdir on /device read/write/setuid/devices/dev=2d90000 on Mon May  2 10:41:43 2011
      MOUNT_OUTPUT

      provider.should be_exists
    end

    it "should be absent if it is missing from mount output" do
      provider.stubs(:mount).returns <<-MOUNT_OUTPUT.gsub(/^\s+/, '')
        / on rpool/ROOT/opensolaris read/write/setuid/devices/dev=2d90002 on Wed Dec 31 16:00:00 1969
        /dev on /dev read/write/setuid/devices/dev=4a40000 on Mon May  2 10:41:43 2011
        /proc on proc read/write/setuid/devices/dev=4b00000 on Mon May  2 10:41:43 2011
      MOUNT_OUTPUT

      provider.should_not be_exists
    end

    it "should be present if it is included in mount output with an incorrect device" do
      provider.stubs(:mount).returns <<-MOUNT_OUTPUT.gsub(/^\s+/, '')
        / on rpool/ROOT/opensolaris read/write/setuid/devices/dev=2d90002 on Wed Dec 31 16:00:00 1969
        /dev on /dev read/write/setuid/devices/dev=4a40000 on Mon May  2 10:41:43 2011
        /proc on proc read/write/setuid/devices/dev=4b00000 on Mon May  2 10:41:43 2011
        /mountdir on /different_device read/write/setuid/devices/dev=2d90000 on Mon May  2 10:41:43 2011
      MOUNT_OUTPUT

      provider.should be_exists
    end
  end

  describe "when options are specified" do
    describe "as an array" do
      it "should pass the specified options to the mount command when mounting" do
        resource[:options] = [ "devices", "exec" ]

        provider.expects(:mount).with("-o", "devices,exec", resource[:device], resource[:name])

        provider.create
      end
    end

    describe "as a comma separated string" do
      it "should pass the specified options to the mount command when mounting" do
        resource[:options] = "devices,exec"

        provider.expects(:mount).with("-o", "devices,exec", resource[:device], resource[:name])

        provider.create
      end
    end
  end

  describe "when syncing" do
    before :each do
      # stub so we can apply a catalog without trying to write state.yaml
      Puppet::Util::Storage.stubs(:store)

      Puppet::Type.type(:mountpoint).stubs(:suitableprovider).returns([described_class])

      @catalog = Puppet::Resource::Catalog.new
      @catalog.add_resource(resource)
    end

    describe "when mounted correctly" do
      before :each do
        resource.provider.stubs(:entry).returns(:name => "/mountdir", :device => "/device")
      end

      it "should do nothing if ensure is present" do
        resource.provider.expects(:mount).with {|*args| !args.empty?}.never
        resource.provider.expects(:unmount).never

        @catalog.apply
      end

      it "should unmount if ensure is absent" do
        resource[:ensure] = :absent
        resource.provider.expects(:unmount).with(resource[:name])
        resource.provider.expects(:mount).never

        @catalog.apply
      end
    end

    describe "when mounted incorrectly" do
      before :each do
        resource.provider.stubs(:entry).returns(:name => "/mountdir", :device => "/different_device")
      end

      it "should remount with the correct device if ensure is present" do
        remount = sequence('remount')
        resource.provider.expects(:unmount).with(resource[:name]).in_sequence(remount)
        resource.provider.expects(:mount).with(resource[:device], resource[:name]).in_sequence(remount)

        @catalog.apply
      end

      it "should unmount if ensure is absent" do
        resource[:ensure] = :absent
        resource.provider.expects(:unmount).with(resource[:name])
        resource.provider.expects(:mount).never

        @catalog.apply
      end
    end

    describe "when unmounted" do
      before :each do
        resource.provider.stubs(:entry).returns(:name => nil, :device => nil)
      end

      it "should mount if ensure is present" do
        resource.provider.expects(:unmount).never
        resource.provider.expects(:mount).with(resource[:device], resource[:name])

        @catalog.apply
      end

      it "should pass only one argument to mount if device is not specified" do
        pending "Can't figure out the right way to test this atm; needs to be fixed"
        deviceless_resource = Puppet::Type.type(:mountpoint).new :ensure => :present, :name => "/mountdir"
        deviceless_provider = described_class.new(deviceless_resource)
        deviceless_provider.stubs(:mount).returns <<-MOUNT_OUTPUT.gsub(/^\s+/, '')
          / on rpool/ROOT/opensolaris read/write/setuid/devices/dev=2d90002 on Wed Dec 31 16:00:00 1969
          /dev on /dev read/write/setuid/devices/dev=4a40000 on Mon May  2 10:41:43 2011
          /proc on proc read/write/setuid/devices/dev=4b00000 on Mon May  2 10:41:43 2011
        MOUNT_OUTPUT
        deviceless_catalog = Puppet::Resource::Catalog.new
        deviceless_catalog.add_resource(deviceless_resource)
        
        deviceless_provider.expects(:mount).with("/mountdir").once
        deviceless_catalog.apply
      end

      it "should do nothing if ensure is absent" do
        resource[:ensure] = :absent
        resource.provider.expects(:unmount).never
        resource.provider.expects(:mount).never

        @catalog.apply
      end
    end
  end
end
