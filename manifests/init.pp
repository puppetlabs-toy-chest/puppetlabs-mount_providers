# Sample usage
class mounts {
  mounts::do { '/mnt/export': device => 'master:/export', options => ['ro','hard'] }
}
