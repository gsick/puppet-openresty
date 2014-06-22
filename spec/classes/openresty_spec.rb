require 'spec_helper'

describe 'openresty' do

  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
  let(:parser) { 'future' }

  it { should contain_package('wget') }
  it { should contain_package('perl') }
  it { should contain_package('gcc') }
  it { should contain_package('readline-devel') }
  it { should contain_package('pcre-devel') }
  it { should contain_package('openssl-devel') }

  context 'with default param' do

    it do
      should contain_group('openresty group').with({
        'ensure' => 'present',
        'name'   => 'nginx',
      })
    end

    it do
      should contain_file('openresty home').with({
        'ensure' => 'directory',
        'path'   => '/var/cache/nginx',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0755',
      })
    end

    it do
      should contain_user('openresty user').with({
        'ensure'  => 'present',
        'name'    => 'nginx',
        'groups'  => 'nginx',
        'comment' => 'nginx web server',
        'shell'   => '/sbin/nologin',
        'home'    => '/var/cache/nginx',
        'system'  => 'true',
        'require' => ['Group[openresty group]', 'File[openresty home]'],
      })
    end

    it do
      should contain_exec('download openresty').with({
        'cwd'     => '/tmp',
        'path'    => '/sbin:/bin:/usr/bin',
        'command' => 'wget http://openresty.org/download/ngx_openresty-1.7.0.1.tar.gz',
        'creates' => '/tmp/ngx_openresty-1.7.0.1.tar.gz',
        'notify'  => 'Exec[untar openresty]',
        'require' => 'Package[wget]',
      })
    end

    it do
      should contain_exec('untar openresty').with({
        'cwd'     => '/tmp',
        'path'    => '/sbin:/bin:/usr/bin',
        'command' => 'tar -zxvf ngx_openresty-1.7.0.1.tar.gz',
        'creates' => '/tmp/ngx_openresty-1.7.0.1/configure',
        'notify'  => 'Exec[configure openresty]',
      })
    end

    it do
      should contain_exec('configure openresty').with({
        'cwd'     => '/tmp/ngx_openresty-1.7.0.1',
        'path'    => '/sbin:/bin:/usr/bin',
        'command' => '/tmp/ngx_openresty-1.7.0.1/configure --user=nginx --group=nginx',
        'creates' => '/tmp/ngx_openresty-1.7.0.1/build',
        'require' => ['Package[perl]', 'Package[gcc]', 'Package[readline-devel]', 'Package[pcre-devel]', 'Package[openssl-devel]'],
        'notify'  => 'Exec[install openresty]',
      })
    end

    it do
      should contain_exec('install openresty').with({
        'cwd'     => '/tmp/ngx_openresty-1.7.0.1',
        'path'    => '/sbin:/bin:/usr/bin',
        'command' => 'make && make install',
        'creates' => '/usr/local/openresty/nginx/sbin/nginx',
        'require' => ['User[openresty user]', 'Exec[configure openresty]'],
      })
    end

    it do
      should contain_file('openresty init script').with({
        'ensure'  => 'file',
        'path'    => '/etc/init.d/nginx',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755',
      })
    end

    it do
      should contain_service('nginx').with({
        'ensure'     => 'running',
        'name'       => 'nginx',
        'enable'     => 'true',
        'hasrestart' => 'false',
        'restart'    => '/etc/init.d/nginx reload',
        'require'    => ['Exec[install openresty]', 'File[openresty init script]'],
      })
    end
  end

  context 'with user group param' do
    let(:params) { {:user => 'openresty', :group => 'openresty'} }

    it do
      should contain_group('openresty group').with({
        'ensure' => 'present',
        'name'   => 'openresty',
      })
    end

    it do
      should contain_user('openresty user').with({
        'ensure'  => 'present',
        'name'    => 'openresty',
        'groups'  => 'openresty',
        'comment' => 'nginx web server',
        'shell'   => '/sbin/nologin',
        'home'    => '/var/cache/nginx',
        'system'  => 'true',
        'require' => ['Group[openresty group]', 'File[openresty home]'],
      })
    end

    it do
      should contain_exec('configure openresty').with({
        'cwd'     => '/tmp/ngx_openresty-1.7.0.1',
        'path'    => '/sbin:/bin:/usr/bin',
        'command' => '/tmp/ngx_openresty-1.7.0.1/configure --user=openresty --group=openresty',
        'creates' => '/tmp/ngx_openresty-1.7.0.1/build',
        'require' => ['Package[perl]', 'Package[gcc]', 'Package[readline-devel]', 'Package[pcre-devel]', 'Package[openssl-devel]'],
        'notify'  => 'Exec[install openresty]',
      })
    end
  end
end