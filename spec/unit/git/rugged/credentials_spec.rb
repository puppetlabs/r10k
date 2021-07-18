require 'spec_helper'

describe R10K::Git::Rugged::Credentials, :unless => R10K::Util::Platform.jruby?  || R10K::Util::Platform.windows? do
  before(:all) do
    require 'r10k/git/rugged/credentials'
    require 'rugged/credentials'
  end

  let(:repo) { R10K::Git::Rugged::BareRepository.new("/some/nonexistent/path", "repo.git") }

  subject { described_class.new(repo) }

  after(:each) { R10K::Git.settings.reset! }

  describe "determining the username" do
    before { R10K::Git.settings[:username] = "moderns" }
    after { R10K::Git.settings.reset! }

    it "prefers a username from the URL" do
      user = subject.get_git_username("https://tessier-ashpool.freeside/repo.git", "ashpool")
      expect(user).to eq "ashpool"
    end

    it "uses the username from the Git config when specified" do
      user = subject.get_git_username("https://tessier-ashpool.freeside/repo.git", nil)
      expect(user).to eq "moderns"
    end

    it "falls back to the current user" do
      R10K::Git.settings.reset!
      expect(Etc).to receive(:getlogin).and_return("finn")
      user = subject.get_git_username("https://tessier-ashpool.freeside/repo.git", nil)
      expect(user).to eq "finn"
    end
  end

  describe "generating ssh key credentials" do
    after(:each) { R10K::Git.settings.reset! }

    it "prefers a per-repository SSH private key" do
      allow(File).to receive(:readable?).with("/etc/puppetlabs/r10k/ssh/tessier-ashpool-id_rsa").and_return true
      R10K::Git.settings[:private_key] = "/etc/puppetlabs/r10k/ssh/id_rsa"
      R10K::Git.settings[:repositories] = [{ remote: "ssh://git@tessier-ashpool.freeside/repo.git",
        private_key: "/etc/puppetlabs/r10k/ssh/tessier-ashpool-id_rsa"}]
      creds = subject.get_ssh_key_credentials("ssh://git@tessier-ashpool.freeside/repo.git", nil)
      expect(creds).to be_a_kind_of(Rugged::Credentials::SshKey)
      expect(creds.instance_variable_get(:@privatekey)).to eq("/etc/puppetlabs/r10k/ssh/tessier-ashpool-id_rsa")
    end

    it "falls back to the global SSH private key" do
      allow(File).to receive(:readable?).with("/etc/puppetlabs/r10k/ssh/id_rsa").and_return true
      R10K::Git.settings[:private_key] = "/etc/puppetlabs/r10k/ssh/id_rsa"
      creds = subject.get_ssh_key_credentials("ssh://git@tessier-ashpool.freeside/repo.git", nil)
      expect(creds).to be_a_kind_of(Rugged::Credentials::SshKey)
      expect(creds.instance_variable_get(:@privatekey)).to eq("/etc/puppetlabs/r10k/ssh/id_rsa")
    end

    it "raises an error if no key has been set" do
      R10K::Git.settings[:private_key] = nil
      expect {
        subject.get_ssh_key_credentials("https://tessier-ashpool.freeside/repo.git", nil)
      }.to raise_error(R10K::Git::GitError, /no private key was given/)
    end

    it "raises an error if the private key is unreadable" do
      R10K::Git.settings[:private_key] = "/some/nonexistent/.ssh/key"
      expect(File).to receive(:readable?).with("/some/nonexistent/.ssh/key").and_return false
      expect {
        subject.get_ssh_key_credentials("https://tessier-ashpool.freeside/repo.git", nil)
      }.to raise_error(R10K::Git::GitError, /Unable to use SSH key auth for.*is missing or unreadable/)
    end

    it "generates the rugged sshkey credential type" do
      allow(File).to receive(:readable?).with("/etc/puppetlabs/r10k/ssh/id_rsa").and_return true
      R10K::Git.settings[:private_key] = "/etc/puppetlabs/r10k/ssh/id_rsa"
      creds = subject.get_ssh_key_credentials("https://tessier-ashpool.freeside/repo.git", nil)
      expect(creds).to be_a_kind_of(Rugged::Credentials::SshKey)
      expect(creds.instance_variable_get(:@privatekey)).to eq("/etc/puppetlabs/r10k/ssh/id_rsa")
    end
  end

  describe "generating github app tokens" do
    it 'errors if app id has invalid characters' do
      expect { subject.github_app_token("123A567890", "fake", "300")
      }.to raise_error(R10K::Git::GitError, /App id contains invalid characters/)
    end
    it 'errors if app ttl has invalid characters' do
      expect { subject.github_app_token("123456", "fake", "abc")
      }.to raise_error(R10K::Git::GitError, /Token ttl contains invalid characters/)
    end
    it 'errors if private file does not exist' do
      R10K::Git.settings[:github_app_key] = "/missing/token/file"
      expect(File).to receive(:readable?).with("/missing/token/file").and_return false
      expect {
        subject.github_app_token("123456", R10K::Git.settings[:github_app_key], "300")
      }.to raise_error(R10K::Git::GitError, /App key is missing or unreadable/)
    end
    it 'errors if file is not a valid SSL key' do
      token_file = Tempfile.new('token')
      token_file.write('my_token')
      token_file.close
      R10K::Git.settings[:github_app_key] = token_file.path
      expect(File).to receive(:readable?).with(token_file.path).and_return true
      expect {
        subject.github_app_token("123456", R10K::Git.settings[:github_app_key], "300")
      }.to raise_error(R10K::Git::GitError, /App key is not a valid SSL key/)
      token_file.unlink
    end
  end

  describe "generating token credentials" do
    it 'errors if token file does not exist' do
      R10K::Git.settings[:oauth_token] = "/missing/token/file"
      expect(File).to receive(:readable?).with("/missing/token/file").and_return false
      R10K::Git.settings[:repositories] = [{remote: "https://tessier-ashpool.freeside/repo.git"}]
      expect {
        subject.get_plaintext_credentials("https://tessier-ashpool.freeside/repo.git", nil)
      }.to raise_error(R10K::Git::GitError, /cannot load OAuth token/)
    end

    it 'errors if the token on stdin is not a valid OAuth token' do
      allow($stdin).to receive(:read).and_return("<bad>token")
      R10K::Git.settings[:oauth_token] = "-"
      R10K::Git.settings[:repositories] = [{remote: "https://tessier-ashpool.freeside/repo.git"}]
      expect {
        subject.get_plaintext_credentials("https://tessier-ashpool.freeside/repo.git", nil)
      }.to raise_error(R10K::Git::GitError, /invalid characters/)
    end

    it 'errors if the token in the file is not a valid OAuth token' do
      token_file = Tempfile.new('token')
      token_file.write('my bad \ntoken')
      token_file.close
      R10K::Git.settings[:oauth_token] = token_file.path
      R10K::Git.settings[:repositories] = [{remote: "https://tessier-ashpool.freeside/repo.git"}]
      expect {
        subject.get_plaintext_credentials("https://tessier-ashpool.freeside/repo.git", nil)
      }.to raise_error(R10K::Git::GitError, /invalid characters/)
    end

    it 'prefers per-repo token file' do
      token_file = Tempfile.new('token')
      token_file.write('my_token')
      token_file.close
      R10K::Git.settings[:oauth_token] = "/do/not/use"
      R10K::Git.settings[:repositories] = [{remote: "https://tessier-ashpool.freeside/repo.git",
                                            oauth_token: token_file.path }]
      creds = subject.get_plaintext_credentials("https://tessier-ashpool.freeside/repo.git", nil)
      expect(creds).to be_a_kind_of(Rugged::Credentials::UserPassword)
      expect(creds.instance_variable_get(:@password)).to eq("my_token")
      expect(creds.instance_variable_get(:@username)).to eq("x-oauth-token")
    end

    it 'uses the token from a file as a password' do
      token_file = Tempfile.new('token')
      token_file.write('my_token')
      token_file.close
      R10K::Git.settings[:oauth_token] = token_file.path
      R10K::Git.settings[:repositories] = [{remote: "https://tessier-ashpool.freeside/repo.git"}]
      creds = subject.get_plaintext_credentials("https://tessier-ashpool.freeside/repo.git", nil)
      expect(creds).to be_a_kind_of(Rugged::Credentials::UserPassword)
      expect(creds.instance_variable_get(:@password)).to eq("my_token")
      expect(creds.instance_variable_get(:@username)).to eq("x-oauth-token")
    end

    it 'uses the token from stdin as a password' do
      allow($stdin).to receive(:read).and_return("my_token")
      R10K::Git.settings[:oauth_token] = '-'
      R10K::Git.settings[:repositories] = [{remote: "https://tessier-ashpool.freeside/repo.git"}]
      creds = subject.get_plaintext_credentials("https://tessier-ashpool.freeside/repo.git", nil)
      expect(creds).to be_a_kind_of(Rugged::Credentials::UserPassword)
      expect(creds.instance_variable_get(:@password)).to eq("my_token")
      expect(creds.instance_variable_get(:@username)).to eq("x-oauth-token")
    end

    it 'only reads the token in once' do
      expect($stdin).to receive(:read).and_return("my_token").once
      R10K::Git.settings[:oauth_token] = '-'
      R10K::Git.settings[:repositories] = [{remote: "https://tessier-ashpool.freeside/repo.git"}]
      creds = subject.get_plaintext_credentials("https://tessier-ashpool.freeside/repo.git", nil)
      expect(creds.instance_variable_get(:@password)).to eq("my_token")
      creds = subject.get_plaintext_credentials("https://tessier-ashpool.freeside/repo.git", nil)
      expect(creds.instance_variable_get(:@password)).to eq("my_token")
    end
  end

  describe "generating default credentials" do
    it "generates the rugged default credential type" do
      creds = subject.get_default_credentials("https://azurediamond:hunter2@tessier-ashpool.freeside/repo.git", "azurediamond")
      expect(creds).to be_a_kind_of(Rugged::Credentials::Default)
    end
  end

  describe "generating credentials" do
    it "creates ssh key credentials for the sshkey allowed type" do
      allow(File).to receive(:readable?).with("/etc/puppetlabs/r10k/ssh/id_rsa").and_return true
      R10K::Git.settings[:private_key] = "/etc/puppetlabs/r10k/ssh/id_rsa"
      expect(subject.call("https://tessier-ashpool.freeside/repo.git", nil, [:ssh_key])).to be_a_kind_of(Rugged::Credentials::SshKey)
    end

    it "creates user/password credentials for the default allowed type" do
      expect(subject.call("https://tessier-ashpool.freeside/repo.git", nil, [:plaintext])).to be_a_kind_of(Rugged::Credentials::UserPassword)
    end

    it "creates default credentials when no other types are allowed" do
      expect(subject.call("https://tessier-ashpool.freeside/repo.git", nil, [])).to be_a_kind_of(Rugged::Credentials::Default)
    end

    it "refuses to generate credentials more than 50 times" do
      (1..50).each { subject.call("https://tessier-ashpool.freeside/repo.git", nil, [:plaintext]) }

      expect { subject.call("https://tessier-ashpool.freeside/repo.git", nil, [:plaintext]) }.to raise_error(R10K::Git::GitError, /authentication failed/i)
    end
  end
end
