shared_context 'system module installation' do
  before(:all) { shell 'rm -rf modules' }
  after(:all) { shell 'rm -rf modules' }
end
