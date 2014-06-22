# == Class: openresty
#
# Full description of class example_class here.
#
# === Parameters
#
# Document parameters here.
#
# [*ntp_servers*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*enc_ntp_servers*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { 'example_class':
#    ntp_servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Gamaliel Sick
#
# === Copyright
#
# Copyright 2014 Agilience, Gamaliel Sick, unless otherwise noted.
#
class openresty(
  $version          = hiera('openresty::version', '1.7.0.1'),
  $user             = hiera('openresty::user', 'nginx'),
  $group            = hiera('openresty::group', 'nginx'),
  $nginx_like_install = 

  
  $configure_params = hiera_array('openresty::configure_params', []),
  $tmp              = hiera('openresty::tmp', '/tmp')
) {

  ensure_packages(['wget', 'perl', 'gcc', 'readline-devel', 'pcre-devel', 'openssl-devel'])

  group { 'openresty group':
    ensure => 'present',
    name   => $group,
  }

  file { 'openresty home':
    ensure => 'directory',
    path   => '/var/cache/nginx',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  user { 'openresty user':
    ensure  => 'present',
    name    => $user,
    groups  => $group,
    comment => 'nginx web server',
    shell   => '/sbin/nologin',
    home    => '/var/cache/nginx',
    system  => true,
    require => [Group['openresty group'], File['openresty home']],
  }

  exec { 'download openresty':
    cwd     => $tmp,
    path    => '/sbin:/bin:/usr/bin',
    command => "wget http://openresty.org/download/ngx_openresty-${version}.tar.gz",
    creates => "${tmp}/ngx_openresty-${version}.tar.gz",
    notify  => Exec['untar openresty'],
    require => Package['wget'],
  }

  exec { 'untar openresty':
    cwd     => $tmp,
    path    => '/sbin:/bin:/usr/bin',
    command => "tar -zxvf ngx_openresty-${version}.tar.gz",
    creates => "${tmp}/ngx_openresty-${version}/configure",
    notify  => Exec['configure openresty'],
  }

  validate_array($configure_params)
  $default_params = ["--user=${user}", "--group=${group}"]
  $params = join(concat($configure_params, $default_params), ' ')

  exec { 'configure openresty':
    cwd     => "${tmp}/ngx_openresty-${version}",
    path    => '/sbin:/bin:/usr/bin',
    command => "${tmp}/ngx_openresty-${version}/configure ${params}",
    creates => "${tmp}/ngx_openresty-${version}/build",
    require => Package['perl', 'gcc', 'readline-devel', 'pcre-devel', 'openssl-devel'],
    notify  => Exec['install openresty'],
  }

  exec { 'install openresty':
    cwd     => "${tmp}/ngx_openresty-${version}",
    path    => '/sbin:/bin:/usr/bin',
    command => 'make && make install',
    creates => '/usr/local/openresty/nginx/sbin/nginx',
    require => [User['openresty user'], Exec['configure openresty']],
  }

  $nginx_bin_file  = $nginx_like_install ? {
    true    => '/usr/sbin/nginx',
    default => '/usr/local/openresty/nginx/sbin/nginx',
  }
  $nginx_conf_file = $nginx_like_install ? {
    true    => '/etc/nginx/nginx.conf',
    default => '/usr/local/openresty/nginx/conf/nginx.conf',
  }
  $nginx_pid_file  = $nginx_like_install ? {
    true    => '/var/run/nginx.pid',
    default => '/usr/local/openresty/nginx/logs/nginx.pid',
  }
  $nginx_lock_file = $nginx_like_install ? {
    true    => '/var/lock/subsys/nginx',
    default => '/usr/local/openresty/nginx/logs/nginx',
  }

  file { 'openresty init script':
    ensure  => 'file',
    path    => '/etc/init.d/nginx',
    content => template("${module_name}/openresty.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  service { 'nginx':
    ensure     => running,
    name       => 'nginx',
    enable     => true,
    hasrestart => false,
    restart    => '/etc/init.d/nginx reload',
    require    => [Exec['install openresty'], File['openresty init script']],
  }
}
