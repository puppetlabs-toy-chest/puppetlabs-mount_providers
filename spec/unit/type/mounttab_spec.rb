#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:mounttab) do

  before do
    @class = described_class
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

    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        @class.attrtype(param).should == :param
      end
    end

    [:ensure, :device, :blockdevice, :fstype, :options, :pass, :dump, :atboot, :target].each do |param|
      it "should have a #{param} property" do
        @class.attrtype(param).should == :property
      end
    end

  end

  describe "when validating values" do

    describe "for name" do

      it "should support absolute paths" do
        proc { @class.new(:name => "/foo", :ensure => :present) }.should_not raise_error
      end

      it "should not support whitespace" do
        proc { @class.new(:name => "/foo bar", :ensure => :present) }.should raise_error(Puppet::Error, /name.*whitespace/)
      end

      it "should not allow trailing slashes" do
        proc { @class.new(:name => "/foo/", :ensure => :present) }.should raise_error(Puppet::Error, /mount should be specified without a trailing slash/)
        proc { @class.new(:name => "/foo//", :ensure => :present) }.should raise_error(Puppet::Error, /mount should be specified without a trailing slash/)
      end

    end

    describe "for ensure" do
      it "should support present as a value for ensure" do
        proc { @class.new(:name => "/foo", :ensure => :present) }.should_not raise_error
      end

      it "should support absent as a value for ensure" do
        proc { @class.new(:name => "/foo", :ensure => :absent) }.should_not raise_error
      end
    end

    describe "for device" do

      it "should support normal /dev paths for device" do
        proc { @class.new(:name => "/foo", :ensure => :present, :device => '/dev/hda1') }.should_not raise_error
        proc { @class.new(:name => "/foo", :ensure => :present, :device => '/dev/dsk/c0d0s0') }.should_not raise_error
      end

      it "should support labels for device" do
        proc { @class.new(:name => "/foo", :ensure => :present, :device => 'LABEL=/boot') }.should_not raise_error
        proc { @class.new(:name => "/foo", :ensure => :present, :device => 'LABEL=SWAP-hda6') }.should_not raise_error
      end

      it "should support pseudo devices for device" do
        proc { @class.new(:name => "/foo", :ensure => :present, :device => 'ctfs') }.should_not raise_error
        proc { @class.new(:name => "/foo", :ensure => :present, :device => 'swap') }.should_not raise_error
        proc { @class.new(:name => "/foo", :ensure => :present, :device => 'sysfs') }.should_not raise_error
        proc { @class.new(:name => "/foo", :ensure => :present, :device => 'proc') }.should_not raise_error
      end

      it "should not support whitespace in device" do
        proc { @class.new(:name => "/foo", :ensure => :present, :device => '/dev/my dev/foo') }.should raise_error Puppet::Error, /device.*whitespace/
        proc { @class.new(:name => "/foo", :ensure => :present, :device => "/dev/my\tdev/foo") }.should raise_error Puppet::Error, /device.*whitespace/
      end

    end

    describe "for blockdevice" do

      before :each do
        Facter.stubs(:value).with(:operatingsystem).returns 'Solaris'
      end

      it "should support normal /dev/rdsk paths for blockdevice" do
        proc { @class.new(:name => "/foo", :ensure => :present, :blockdevice => '/dev/rdsk/c0d0s0') }.should_not raise_error
      end

      it "should support a dash for blockdevice" do
        proc { @class.new(:name => "/foo", :ensure => :present, :blockdevice => '-') }.should_not raise_error
      end

      it "should not support whitespace in blockdevice" do
        proc { @class.new(:name => "/foo", :ensure => :present, :blockdevice => '/dev/my dev/foo') }.should raise_error Puppet::Error, /blockdevice.*whitespace/
        proc { @class.new(:name => "/foo", :ensure => :present, :blockdevice => "/dev/my\tdev/foo") }.should raise_error Puppet::Error, /blockdevice.*whitespace/
      end

      it "should default to /dev/rdsk/DEVICE if device is /dev/dsk/DEVICE" do
        obj = @class.new(:name => "/foo", :device => '/dev/dsk/c0d0s0')
        obj[:blockdevice].should == '/dev/rdsk/c0d0s0'
      end

      it "should default to - if it is an nfs-share" do
        obj = @class.new(:name => "/foo", :device => "server://share", :fstype => 'nfs')
        obj[:blockdevice].should == '-'
      end

      it "should have no default otherwise" do
        @class.new(:name => "/foo")[:blockdevice].should == nil
        @class.new(:name => "/foo", :device => "/foo")[:blockdevice].should == nil
      end

      it "should overwrite any default if blockdevice is explicitly set" do
        @class.new(:name => "/foo", :device => '/dev/dsk/c0d0s0', :blockdevice => '/foo')[:blockdevice].should == '/foo'
        @class.new(:name => "/foo", :device => "server://share", :fstype => 'nfs', :blockdevice => '/foo')[:blockdevice].should == '/foo'
      end

    end

    describe "for fstype" do

      it "should support valid fstypes" do
        proc { @class.new(:name => "/foo", :ensure => :present, :fstype => 'ext3') }.should_not raise_error
        proc { @class.new(:name => "/foo", :ensure => :present, :fstype => 'proc') }.should_not raise_error
        proc { @class.new(:name => "/foo", :ensure => :present, :fstype => 'sysfs') }.should_not raise_error
      end

      it "should support auto as a special fstype" do
        proc { @class.new(:name => "/foo", :ensure => :present, :fstype => 'auto') }.should_not raise_error
      end

      it "should not support whitespace in fstype" do
        proc { @class.new(:name => "/foo", :ensure => :present, :fstype => 'ext 3') }.should raise_error Puppet::Error, /fstype.*whitespace/
      end

    end

    describe "for options" do

      it "should support a single option" do
         proc { @class.new(:name => "/foo", :ensure => :present, :options => 'ro') }.should_not raise_error
      end

      it "should support muliple options as an array" do
        proc { @class.new(:name => "/foo", :ensure => :present, :options => ['ro','rsize=4096']) }.should_not raise_error
      end

      it "should support an empty array as options" do
        proc { @class.new(:name => "/foo", :ensure => :present, :options => []) }.should_not raise_error
      end

      it "should not support a comma separated option" do
        proc { @class.new(:name => "/foo", :ensure => :present, :options => ['ro','foo,bar','intr']) }.should raise_error Puppet::Error, /option.*have to be specified as an array/
      end

      it "should not support blanks in options" do
        proc { @class.new(:name => "/foo", :ensure => :present, :options => ['ro','foo bar','intr']) }.should raise_error Puppet::Error, /option.*whitespace/
      end

    end

    describe "for pass" do

      it "should support numeric values" do
        proc { @class.new(:name => "/foo", :ensure => :present, :pass => '0') }.should_not raise_error
        proc { @class.new(:name => "/foo", :ensure => :present, :pass => '1') }.should_not raise_error
        proc { @class.new(:name => "/foo", :ensure => :present, :pass => '2') }.should_not raise_error
      end

      it "should support - on Solaris" do
        Facter.stubs(:value).with(:operatingsystem).returns 'Solaris'
        proc { @class.new(:name => "/foo", :ensure => :present, :pass => '-') }.should_not raise_error
      end

      it "should default to 0 on non Solaris" do
        Facter.stubs(:value).with(:operatingsystem).returns 'HP-UX'
        @class.new(:name => "/foo", :ensure => :present)[:pass].should == 0
      end

      it "should default to - on Solaris" do
        Facter.stubs(:value).with(:operatingsystem).returns 'Solaris'
        @class.new(:name => "/foo", :ensure => :present)[:pass].should == '-'
      end

    end

    describe "for dump" do

      it "should support 0 as a value for dump" do
        proc { @class.new(:name => "/foo", :ensure => :present, :dump => '0') }.should_not raise_error
      end

      it "should support 1 as a value for dump" do
        proc { @class.new(:name => "/foo", :ensure => :present, :dump => '1') }.should_not raise_error
      end

      # stefan: Looks like I'm unable to stub facter here
      it "should support 2 as a value for dump on FreeBSD", :if => Facter.value(:operatingsystem) == 'FreeBSD' do
        proc { @class.new(:name => "/foo", :ensure => :present, :dump => '2') }.should_not raise_error
      end

      # stefan: Looks like I'm unable to stub facter here
      it "should not support 2 as a value for dump when not on FreeBSD", :if => Facter.value(:operatingsystem) != 'FreeBSD' do
        proc { @class.new(:name => "/foo", :ensure => :present, :dump => '2') }.should raise_error Puppet::Error, /Invalid value/
      end

      it "should default to 0" do
        @class.new(:name => "/foo", :ensure => :present)[:dump].should == 0
      end

    end

    describe "for atboot" do

      it "should support true as a value for atboot" do
        proc { @class.new(:name => "/foo", :ensure => :present, :atboot => :true) }.should_not raise_error
      end

      it "should support false as a value for atboot" do
        proc { @class.new(:name => "/foo", :ensure => :present, :atboot => :false) }.should_not raise_error
      end

      it "should support yes as a value for atboot" do
        proc { @class.new(:name => "/foo", :ensure => :present, :atboot => :yes) }.should_not raise_error
      end

      it "should support no as a value for atboot" do
        proc { @class.new(:name => "/foo", :ensure => :present, :atboot => :no) }.should_not raise_error
      end

      it "should alias true to yes" do
        @class.new(:name => "/foo", :ensure => :present, :atboot => :true)[:atboot].should == :yes
      end

      it "should alias false to no" do
        @class.new(:name => "/foo", :ensure => :present, :atboot => :false)[:atboot].should == :no
      end

      it "should not support other values for atboot" do
        proc { @class.new(:name => "/foo", :ensure => :present, :atboot => :please_dont) }.should raise_error Puppet::Error, /Invalid value/
      end

    end

  end

  describe "when syncing options" do

    before :each do
      @options = @class.attrclass(:options).new(:resource => @resource, :should => %w{rw rsize=2048 wsize=2048})
    end

    it "should pass the sorted joined array to the provider" do
      @provider.expects(:options=).with('rsize=2048,rw,wsize=2048')
      @options.sync
    end

    it "should report out of sync if one option is missing" do
      @options.insync?(%w{rw rsize=2048}).should == false
    end

    it "should report out of sync if there is an unwanted option" do
      @options.insync?(%w{rw rsize=2048 wsize=2048 intr}).should == false
    end

    it "should report out of sync if at least one option is incorrect" do
      @options.insync?(%w{rw rsize=1024 wsize=2048}).should == false
    end

    it "should not care about the order of options" do
      @options.insync?(%w{rw rsize=2048 wsize=2048}).should == true
      @options.insync?(%w{rw wsize=2048 rsize=2048}).should == true
      @options.insync?(%w{rsize=2048 rw wsize=2048}).should == true
      @options.insync?(%w{rsize=2048 wsize=2048 rw}).should == true
      @options.insync?(%w{wsize=2048 rw rsize=2048}).should == true
      @options.insync?(%w{wsize=2048 rsize=2048 rw}).should == true
      @options.insync?(%w{rw rsize=2048 wsize=2048}).should == true
    end

  end

end
