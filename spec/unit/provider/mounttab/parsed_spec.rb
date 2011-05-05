#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:mounttab).provider(:parsed) do

  before :each do
    @mounttab_class = Puppet::Type.type(:mounttab)
    @provider = @mounttab_class.provider(:parsed)
    @provider.stubs(:suitable?).returns true
  end

  # LAK:FIXME I can't mock Facter because this test happens at parse-time.
  it "should default to /etc/vfstab on Solaris" do
    pending "This test only works on Solaris" unless Facter.value(:operatingsystem) == 'Solaris'
    @provider.default_target.should == '/etc/vfstab'
  end

  it "should default to /etc/fstab on anything else" do
    pending "This test does not work on Solaris" if Facter.value(:operatingsystem) == 'Solaris'
    @provider.default_target.should == '/etc/fstab'
  end

  describe "when parsing a line" do

    it "should not crash on incomplete lines in fstab" do
      parse = @provider.parse <<-FSTAB
/dev/incomplete
/dev/device       name
FSTAB
      lambda{ @provider.to_line(parse[0]) }.should_not raise_error
    end


    describe "on Solaris", :if => Facter.value(:operatingsystem) == 'Solaris' do

      before :each do
        @example_line = "/dev/dsk/c0d0s0 /dev/rdsk/c0d0s0 \t\t    /  \t    ufs     1 no\t-"
      end

      it "should extract device from the first field" do
        @provider.parse_line(@example_line)[:device].should == '/dev/dsk/c0d0s0'
      end

      it "should extract blockdevice from second field" do
        @provider.parse_line(@example_line)[:blockdevice].should == "/dev/rdsk/c0d0s0"
      end

      it "should extract name from third field" do
        @provider.parse_line(@example_line)[:name].should == "/"
      end

      it "should extract fstype from fourth field" do
        @provider.parse_line(@example_line)[:fstype].should == "ufs"
      end

      it "should extract pass from fifth field" do
        @provider.parse_line(@example_line)[:pass].should == "1"
      end

      it "should extract atboot from sixth field" do
        @provider.parse_line(@example_line)[:atboot].should == "no"
      end

      it "should extract options from seventh field" do
        @provider.parse_line(@example_line)[:options].should == "-"
      end

    end

    describe "on other platforms than Solaris", :if => Facter.value(:operatingsystem) != 'Solaris' do

      before :each do
        @example_line = "/dev/vg00/lv01\t/spare   \t  \t   ext3    defaults\t1 2"
      end

      it "should extract device from the first field" do
        @provider.parse_line(@example_line)[:device].should == '/dev/vg00/lv01'
      end

      it "should extract name from second field" do
        @provider.parse_line(@example_line)[:name].should == "/spare"
      end

      it "should extract fstype from third field" do
        @provider.parse_line(@example_line)[:fstype].should == "ext3"
      end

      it "should extract options from fourth field" do
        @provider.parse_line(@example_line)[:options].should == "defaults"
      end

      it "should extract dump from fifth field" do
        @provider.parse_line(@example_line)[:dump].should == "1"
      end

      it "should extract options from sixth field" do
        @provider.parse_line(@example_line)[:pass].should == "2"
      end

    end

  end

end
