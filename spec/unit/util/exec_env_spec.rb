require 'r10k/util/exec_env'

describe R10K::Util::ExecEnv do
  describe "withenv" do
    it "adds the keys to the environment during the block" do
      val = nil
      described_class.withenv('VAL' => 'something') do
        val = ENV['VAL']
      end
      expect(val).to eq 'something'
    end

    it "doesn't modify values that were not modified by the passed hash" do
      origpath = ENV['PATH']
      path = nil
      described_class.withenv('VAL' => 'something') do
        path = ENV['PATH']
      end
      expect(path).to eq origpath
    end

    it "removes new values after the block" do
      val = nil
      described_class.withenv('VAL' => 'something') { }
      expect(ENV['VAL']).to be_nil
    end

    it "restores old values after the block" do
      path = ENV['PATH']
      described_class.withenv('PATH' => '/usr/bin') { }
      expect(ENV['PATH']).to eq path
    end
  end

  describe "reset" do

    after { ENV.delete('VAL') }

    it "replaces environment keys with the specified keys" do
      ENV['VAL'] = 'hi'

      newenv = ENV.to_hash
      newenv['VAL'] = 'bye'

      described_class.reset(newenv)
      expect(ENV['VAL']).to eq 'bye'
    end

    it "removes any keys that were not provided" do
      env = ENV.to_hash
      ENV['VAL'] = 'hi'
      described_class.reset(env)
      expect(ENV['VAL']).to be_nil
    end
  end
end
