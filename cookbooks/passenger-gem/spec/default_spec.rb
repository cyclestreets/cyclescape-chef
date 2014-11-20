require 'spec_helper'

describe 'passenger-gem::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  before do
    stub_command("/usr/sbin/apache2 -t").and_return(true)
    stub_command("test -f /var/lib/gems/1.9.1/gems/passenger-4.0.53/ext/apache2/mod_passenger.so").and_return(false)
  end

  it 'should create a template with the correct version' do
    expect(chef_run).to render_file('/etc/apache2/mods-available/passenger.load')
      .with_content('LoadModule passenger_module /var/lib/gems/1.9.1/gems/passenger-4.0.53/ext/apache2/mod_passenger.so')
  end
end
