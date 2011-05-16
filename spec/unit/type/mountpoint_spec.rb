#/usr/bin/env ruby

require 'spec_helper'

mountpoint = Puppet::Type.type(:mountpoint)

describe mountpoint do

  before do
    @class = mountpoint
    @provider_class = @class.provide(:fake) { mk_resource_methods }
    @provider = @provider_class.new
    @resource = stub 'resource', :resource => nil, :provider => @provider

    @class.stubs(:defaultprovider).returns @provider_class
    @class.any_instance.stubs(:provider).returns @provider
  end

  it "should have :name as its keyattribute" do
    @class.key_attributes.should == [:name]
  end

  describe "when validating attributes" do

    [:name, :provider, :options].each do |param|
      it "should have a #{param} parameter" do
        @class.attrtype(param).should == :param
      end
    end

    [:ensure, :device].each do |param|
      it "should have a #{param} property" do
        @class.attrtype(param).should == :property
      end
    end
  end

  describe "when validating values" do

    describe "for ensure" do
      it "should support mounted as a value for ensure" do
        pending "mounted and unmounted not yet supported"

        proc { @class.new(:name => "/mnt/foo", :ensure => :mounted) }.should_not raise_error
      end

      it "should support present as a value for ensure" do
        proc { @class.new(:name => "/mnt/foo", :ensure => :present) }.should_not raise_error
      end

      it "should support unmounted as a value for ensure" do
        pending "mounted and unmounted not yet supported"

        proc { @class.new(:name => "/mnt/foo", :ensure => :unmounted) }.should_not raise_error
      end

      it "should support absent as a value for ensure" do
        proc { @class.new(:name => "/mnt/foo", :ensure => :absent) }.should_not raise_error
      end
    end

    describe "for name" do

      it "should support normal paths for name" do
        proc { @class.new(:name => "/mnt/foo", :ensure => :present) }.should_not raise_error
        proc { @class.new(:name => "/media/cdrom_foo_bar", :ensure => :present) }.should_not raise_error
      end

      it "should not support spaces in name" do
        proc { @class.new(:name => "/mnt/foo bar", :ensure => :present) }.should raise_error(Puppet::Error, /name is not allowed to contain whitespace/)
        proc { @class.new(:name => "/m nt/foo", :ensure => :present) }.should raise_error(Puppet::Error, /name is not allowed to contain whitespace/)
      end

      # ticket 6793
      it "should not support trailing slashes" do
        proc { @class.new(:name => "/mnt/foo/", :ensure => :present) }.should raise_error(Puppet::Error, /name is not allowed to have trailing slashes/)
        proc { @class.new(:name => "/mnt/foo//", :ensure => :present) }.should raise_error(Puppet::Error, /name is not allowed to have trailing slashes/)
      end

      it "should not allow relative paths" do
        proc { @class.new(:name => "mnt/foo", :ensure => :present) }.should raise_error(Puppet::Error, /name must be an absolute path/)
        proc { @class.new(:name => "./foo", :ensure => :present) }.should raise_error(Puppet::Error, /name must be an absolute path/)
        proc { @class.new(:name => "/foo/bar/../baz", :ensure => :present) }.should raise_error(Puppet::Error, /name must be an absolute path/)
      end

    end


    describe "for device" do

      it "should support normal /dev paths for device" do
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :device => '/dev/hda1') }.should_not raise_error
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :device => '/dev/dsk/c0d0s0') }.should_not raise_error
      end

      it "should support labels for device" do
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :device => 'LABEL=/boot') }.should_not raise_error
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :device => 'LABEL=SWAP-hda6') }.should_not raise_error
      end

      it "should support pseudo devices for device" do
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :device => 'ctfs') }.should_not raise_error
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :device => 'swap') }.should_not raise_error
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :device => 'sysfs') }.should_not raise_error
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :device => 'proc') }.should_not raise_error
      end

      it "should not support blanks in device" do
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :device => '/dev/my dev/foo') }.should raise_error
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :device => "/dev/my\tdev/foo") }.should raise_error
      end

    end

    describe "for fstype" do
      it "should support single-word fstypes" do
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :fstype => 'ext3') }.should_not raise_error
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :fstype => 'bazinga') }.should_not raise_error
      end

      it "should not support blanks in fstype" do
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :fstype => 'ext 3') }.should raise_error
      end
    end

    describe "for options" do

      it "should support a single option" do
         proc { @class.new(:name => "/mnt/foo", :ensure => :present, :options => 'ro') }.should_not raise_error
      end

      it "should support muliple options as an array" do
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :options => ['ro','rsize=4096']) }.should_not raise_error
      end

      it "should support an empty array as options" do
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :options => []) }.should_not raise_error
      end

      it "should not support blanks in options" do
        proc { @class.new(:name => "/mnt/foo", :ensure => :present, :options => ['ro','foo bar','intr']) }.should raise_error(Puppet::Error, /options cannot contain any spaces/)
      end
    end
  end
end
