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

  context "with default param" do

    it do
      should_contain_group('openresty group').with({
        'ensure' => 'present',
        'name'   => 'nginx',
      })
    end

    it do
      should_contain_user('openresty user').with({
        'ensure'  => 'present',
        'name'    => 'nginx',
        'groups'  => 'nginx',
        'comment' => 'nginx web server',
        'shell'   => '/sbin/nologin',
        'system'  => 'true',
        'require' => 'Group[openresty group]',
      })
    end

    it do
      should_contain_exec('download openresty').with({
        'cwd'     => '/tmp',
        'path'    => '/sbin:/bin:/usr/bin',
        'command' => 'wget http://openresty.org/download/ngx_openresty-1.7.0.1.tar.gz',
        'creates' => '/tmp/ngx_openresty-1.7.0.1.tar.gz',
        'notify'  => 'Exec[untar openresty]',
        'require' => 'Package[wget]',
      })
    end

    it do
      should_contain_exec('untar openresty').with({
        'cwd'     => '/tmp',
        'path'    => '/sbin:/bin:/usr/bin',
        'command' => 'tar -zxvf ngx_openresty-1.7.0.1.tar.gz',
        'creates' => '/tmp/ngx_openresty-1.7.0.1/configure',
        'notify'  => 'Exec[configure openresty]',
      })
    end

    it do
      should_contain_exec('configure openresty').with({
        'cwd'     => '/tmp/ngx_openresty-1.7.0.1',
        'path'    => '/sbin:/bin:/usr/bin',
        'command' => '/tmp/ngx_openresty-1.7.0.1/configure --user=nginx --group=nginx',
        'creates' => '/tmp/ngx_openresty-1.7.0.1/build',
        'require' => ['Package[perl]', 'Package[gcc]', 'Package[readline-devel]', 'Package[pcre-devel]', 'Package[openssl-devel]'],
        'notify'  => 'Exec[install openresty]',
      })
    end
    
  end
end