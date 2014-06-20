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
  $configure_params = hiera('openresty::configure_params', []),
  $tmp              = hiera('openresty::tmp', '/tmp')
) {

  ensure_packages(['wget', 'perl', 'gcc', 'readline-devel', 'pcre-devel', 'openssl-devel'])

  group { 'openresty group':
    name   => "${group}",
    ensure => 'present',
  }

  user { 'openresty user':
    name    => "${user}",
    ensure  => 'present',
    groups  => "${group}",
    comment => 'nginx web server',
    shell   => '/sbin/nologin',
    system  => true,
    require => Group['openresty group'],
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
  concat($default_params, '--sbin-path=/usr/sbin/nginx')
  concat($default_params, '--conf-path=/etc/nginx/nginx.conf')
  concat($default_params, '--pid-path=/var/run/nginx.pid')
  concat($default_params, '--lock-path=/var/lock/subsys/nginx.lock')
  concat($default_params, '--error-log-path=/var/log/nginx/error.log')
  concat($default_params, '--http-log-path=/var/log/nginx/access.log')
  concat($default_params, '--http-client-body-temp-path=/var/cache/nginx/client_temp')
  concat($default_params, '--http-proxy-temp-path=/var/cache/nginx/proxy_temp')
  concat($default_params, '--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp')
  concat($default_params, '--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp')
  concat($default_params, '--http-scgi-temp-path=/var/cache/nginx/scgi_temp')
  concat($default_params, '--with-http_gzip_static_module')

  concat($configure_params, $default_params)
  $params = join($configure_params, ' ')

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

  service { 'nginx':
    ensure     => running,
    name       => 'nginx',
    enable     => true,
    hasrestart => false,
    restart    => '/etc/init.d/nginx reload',
    require    => Exec['install openresty'],
  }
}
