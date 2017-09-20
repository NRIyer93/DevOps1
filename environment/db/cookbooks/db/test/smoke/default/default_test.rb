# # encoding: utf-8

# Inspec test for recipe db::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

unless os.windows?
  # This is an example test, replace with your own test.
  describe user('root'), :skip do
    it { should exist }
  end
end

describe port(80) do
  it { should_not be_listening }
end

# Test to check if mongodb is installed
describe package 'mongodb' do
	it { should be_installed }
end

# Test to check if mongodb is both enabled and running
describe service 'mongodb' do 
	it {should be_running }
	it {should be_enabled }
end


