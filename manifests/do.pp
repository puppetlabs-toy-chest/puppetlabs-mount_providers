# definition that uses the puppetlabs mounttab/mountpoint providers
# if 'options' are specified, they need to come in as an ARRAY
# not a quoted string, i.e
# mount_providers::do { "/mnt":
#   device => "filer:/export", options => ["ro","hard","proto=tcp"] }

define mount_providers::do($device, $options="DEFAULT") {
# this define wraps the 'mount' type with reasonable defaults

# make sure the parent of the mountpoint exists - there's no 'mkdir -p' equivalent in puppet
# note this only makes two levels of directories deep - mount point and its immediate parent

  $parentpath = inline_template("<%= arry = name.split('/'); if arry.length > 2; arry.slice(0..-2).join('/'); else name end %>")

  if ! defined(File["$parentpath"]) {
    file { "$parentpath":  ensure => directory }
  }

  # make sure the mountpoint exists, create it as a directory if not
  if ! defined(File[$name]) {
    file { $name: ensure => directory }
  }

  # handle mount options
  if $options != "DEFAULT" {
    $mountopts = $options
  } else {
    $mountopts =  $operatingsystem ? {
      solaris => [ "rw","hard","proto=tcp","vers=3" ],
      linux   => [ "rw","hard","proto=tcp" ],
    }
  }

  mounttab { $name:
    device      => $device,
    options     => $mountopts,
    ensure      => present,
    blockdevice => "-",
    fstype      => nfs,
    pass        => 0,
    dump        => 0,
    atboot      => "yes",
    notify      => Mountpoint[$name],
  }

  mountpoint { $name:
    require  => [ Mounttab[$name], File[$name] ],
    device   => $device,
    options  => $mountopts,
    remounts => false,
    ensure   => present,
  }
}
