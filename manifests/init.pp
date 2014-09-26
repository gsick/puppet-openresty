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
  $version                = '1.7.2.1',
  $nginx_version          = '1.7.2',
  $user                   = 'nginx',
  $group                  = 'nginx',
  $user_uid               = undef,
  $group_gid              = undef,
  $nginx_like_install     = false,
  $configure_params       = [],
  $with_pcre              = false,
  $pcre_version           = '8.35',
  $with_lua_resty_http    = false,
  $lua_resty_http_version = '0.03',
  $with_statsd            = false,
  $statsd_version         = 'master',
  $tmp                    = '/tmp',
  $service_ensure         = 'running',
  $service_enable         = true,
  $server_name            = 'openresty',
) {

  validate_string($version)
  validate_string($nginx_version)
  validate_string($user)
  validate_string($group)
  validate_bool($nginx_like_install)
  validate_array($configure_params)
  validate_bool($with_pcre)
  validate_string($pcre_version)
  validate_bool($with_lua_resty_http)
  validate_string($lua_resty_http_version)
  validate_bool($with_statsd)
  validate_string($statsd_version)
  validate_absolute_path($tmp)
  validate_string($service_ensure)
  validate_bool($service_enable)
  validate_string($server_name)

  ensure_packages(['wget', 'perl', 'gcc', 'readline-devel', 'pcre-devel', 'openssl-devel'])

  if($group_gid) {
    group { 'openresty group':
      ensure => 'present',
      name   => $group,
      gid    => $group_gid,
    }
  } else {
    group { 'openresty group':
      ensure => 'present',
      name   => $group,
    }
  }

  file { 'openresty home':
    ensure => 'directory',
    path   => '/var/cache/nginx',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  if($user_uid) {
    user { 'openresty user':
      ensure  => 'present',
      name    => $user,
      groups  => $group,
      uid     => $user_uid,
      comment => 'nginx web server',
      shell   => '/sbin/nologin',
      home    => '/var/cache/nginx',
      system  => true,
      require => [Group['openresty group'], File['openresty home']],
    }
  } else {
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

  file { 'nginx.h':
    ensure  => 'file',
    path    => "${tmp}/ngx_openresty-${version}/bundle/nginx-${nginx_version}/src/core/nginx.h",
    content => template("${module_name}/nginx/src/core/nginx.h.erb"),
    require => Exec['untar openresty'],
    notify  => Exec['configure openresty'],
  }

  file { 'ngx_http_header_filter_module.c':
    ensure  => 'file',
    path    => "${tmp}/ngx_openresty-${version}/bundle/nginx-${nginx_version}/src/http/ngx_http_header_filter_module.c",
    content => template("${module_name}/nginx/src/http/ngx_http_header_filter_module.c.erb"),
    require => Exec['untar openresty'],
    notify  => Exec['configure openresty'],
  }

  file { 'ngx_http_spdy_filter_module.c':
    ensure  => 'file',
    path    => "${tmp}/ngx_openresty-${version}/bundle/nginx-${nginx_version}/src/http/ngx_http_spdy_filter_module.c",
    content => template("${module_name}/nginx/src/http/ngx_http_spdy_filter_module.c.erb"),
    require => Exec['untar openresty'],
    notify  => Exec['configure openresty'],
  }

  file { 'ngx_http_special_response.c':
    ensure  => 'file',
    path    => "${tmp}/ngx_openresty-${version}/bundle/nginx-${nginx_version}/src/http/ngx_http_special_response.c",
    content => template("${module_name}/nginx/src/http/ngx_http_special_response.c.erb"),
    require => Exec['untar openresty'],
    notify  => Exec['configure openresty'],
  }

  if($with_statsd) {
    exec { 'download nginx-statsd':
      cwd     => $tmp,
      path    => '/sbin:/bin:/usr/bin',
      command => "wget -O nginx-statsd-${statsd_version}.tar.gz https://github.com/zebrafishlabs/nginx-statsd/tarball/${statsd_version}",
      creates => "${tmp}/nginx-statsd-${statsd_version}.tar.gz",
      notify  => Exec['untar nginx-statsd'],
      require => Package['wget'],
    }

    exec { 'untar nginx-statsd':
      cwd     => $tmp,
      path    => '/sbin:/bin:/usr/bin',
      command => "mkdir nginx-statsd-${statsd_version} && tar -zxvf nginx-statsd-${statsd_version}.tar.gz -C /tmp/nginx-statsd-master --strip-components 1",
      creates => "${tmp}/nginx-statsd-${statsd_version}/config",
      notify  => Exec['configure openresty'],
    }

    $statsd_params = ["--add-module=${tmp}/nginx-statsd-${statsd_version}"]
  }

  if($with_pcre) {
    exec { 'download pcre':
      cwd     => $tmp,
      path    => '/sbin:/bin:/usr/bin',
      command => "wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${pcre_version}.tar.bz2",
      creates => "${tmp}/pcre-${pcre_version}.tar.bz2",
      notify  => Exec['untar pcre'],
      require => Package['wget'],
    }

    exec { 'untar pcre':
      cwd     => $tmp,
      path    => '/sbin:/bin:/usr/bin',
      command => "tar xjf pcre-${pcre_version}.tar.bz2",
      creates => "${tmp}/pcre-${pcre_version}/configure",
      notify  => Exec['configure openresty'],
    }

    $pcre_params = ["--with-pcre",
                    "--with-pcre=${tmp}/pcre-${pcre_version}",
                    "--with-pcre-conf-opt=--enable-utf",
                    "--with-pcre-jit"]
  }

  $user_params = ["--user=${user}", "--group=${group}"]

  if($with_pcre and $with_statsd) {
    $default_params = concat($user_params, concat($pcre_params, $statsd_params))
  } elsif($with_pcre) {
    $default_params = concat($user_params, $pcre_params)
  } elsif($with_statsd) {
    $default_params = concat($user_params, $statsd_params)
  } else {
    $default_params = $user_params
  }

  $params = join(concat($configure_params, $default_params), ' ')

  exec { 'configure openresty':
    cwd     => "${tmp}/ngx_openresty-${version}",
    path    => '/sbin:/bin:/usr/bin',
    command => "${tmp}/ngx_openresty-${version}/configure ${params}",
    creates => "${tmp}/ngx_openresty-${version}/build",
    require => [Exec['untar openresty'], Package['perl', 'gcc', 'readline-devel', 'pcre-devel', 'openssl-devel']],
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
  $nginx_log_dir   = $nginx_like_install ? {
    true    => '/var/log/nginx',
    default => '/usr/local/openresty/nginx/logs',
  }

  file { 'openresty logrotate':
    ensure  => 'file',
    path    => '/etc/logrotate.d/nginx',
    content => template("${module_name}/openresty.logrotate.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
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
    ensure     => $service_ensure,
    name       => 'nginx',
    enable     => $service_enable,
    hasstatus  => true,
    hasrestart => false,
    restart    => '/etc/init.d/nginx reload',
    require    => [Exec['install openresty'], File['openresty init script']],
  }

  if($with_lua_resty_http) {
    exec { 'download lua-resty-http':
      cwd     => $tmp,
      path    => '/sbin:/bin:/usr/bin',
      command => "wget -O lua-resty-http-${lua_resty_http_version}.tar.gz https://github.com/pintsized/lua-resty-http/archive/v${lua_resty_http_version}.tar.gz",
      creates => "${tmp}/lua-resty-http-${lua_resty_http_version}.tar.gz",
      notify  => Exec['untar lua-resty-http'],
      require => Package['wget'],
    }

    exec { 'untar lua-resty-http':
      cwd     => $tmp,
      path    => '/sbin:/bin:/usr/bin',
      command => "tar -zxvf lua-resty-http-${lua_resty_http_version}.tar.gz",
      creates => "${tmp}/lua-resty-http-${lua_resty_http_version}/Makefile",
      notify  => Exec['install lua-resty-http'],
    }

    exec { 'install lua-resty-http':
      cwd     => "${tmp}/lua-resty-http-${lua_resty_http_version}",
      path    => '/sbin:/bin:/usr/bin',
      command => "cp -f lib/resty/http.lua /usr/local/openresty/lualib/resty",
      creates => "/usr/local/openresty/lualib/resty/http.lua",
      require => Exec['install openresty'],
      notify  => Service['nginx'],
    }
  }

}
