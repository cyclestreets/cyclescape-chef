require 'spec_helper'

describe 'rubygems' do
  describe command('gem -v') do
    it { should return_stdout /2.0.0/ }
  end
end
