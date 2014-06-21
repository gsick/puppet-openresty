require 'spec_helper'

describe 'openresty' do

  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
  let(:parser) { 'future' }

  it { should contain_package('wget') }
  it { should contain_package('perl') }

end