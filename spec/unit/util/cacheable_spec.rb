require 'spec_helper'
require 'r10k/util/cacheable'

RSpec.describe R10K::Util::Cacheable do

  subject { Object.new.extend(R10K::Util::Cacheable) }

  describe "dirname sanitization" do
    let(:input) { 'git://some/git/remote' }

    it 'sanitizes URL to directory name' do
      expect(subject.sanitized_dirname(input)).to eq('git---some-git-remote')
    end

    context 'with username and password' do
      let(:input) { 'https://"user:pa$$w0rd:@authenticated/git/remote' }

      it 'sanitizes authenticated URL to directory name' do
        expect(subject.sanitized_dirname(input)).to eq('https---authenticated-git-remote')
      end
    end
  end
end
