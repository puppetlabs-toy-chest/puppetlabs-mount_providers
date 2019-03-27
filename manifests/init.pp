# Sample usage
#
# Class names need to match module names for the autoloader to find them.
class mount_providers {
  mount_providers::do { '/mnt/export':
    device  => 'master:/export',
    options => ['ro','hard'],
  }

  # notify { "remount":
  #   message => "remount",
  #   notify  => Mount_providers::Do['/mnt/export'],
  # }
}
