require 'spec_helper'

describe 'passenger-gem::default' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['brightbox-ruby']['version'] = "#{ruby_version}"
      node.set['cyclescape']['gem_folder'] = "#{ruby_version}.0"
    end.converge(described_recipe)
  end
  let(:ruby_version) { '2.1' }

  before do
    stub_command("/usr/sbin/apache2 -t").and_return(true)
    stub_command("test -f /var/lib/gems/#{ruby_version}.0/gems/passenger-4.0.53/buildout/apache2/mod_passenger.so").and_return(false)
  end

  it 'should create a template with the correct version' do
    expect(chef_run).to render_file('/etc/apache2/mods-available/passenger.load')
      .with_content("LoadModule passenger_module /var/lib/gems/#{ruby_version}.0/gems/passenger-4.0.53/buildout/apache2/mod_passenger.so")
  end
end
