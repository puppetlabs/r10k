require 'spec_helper'
require 'r10k/util/core_ext/hash_ext'

describe R10K::Util::CoreExt::HashExt::SymbolizeKeys do
  it "doesn't monky patch core types" do
    # And now for a diatribe on monkey patching.
    #
    # Seriously. Monkey patching objects on a global objects without a very
    # good reason is evil. On a case by case basis, sure, it can make life
    # a bit easier but it also can grossly complicate things. If you do need to
    # add a method to every type of an object because it'll be used everywhere,
    # go for it. However if you only need a given method in a limited area,
    # `Object#extend` is your friend.
    #
    # Fin.
    expect(Hash.new).to_not respond_to(:symbolize_keys!)
  end

  describe "on an instance that extends #{described_class}" do
    subject { Hash.new.extend(described_class) }

    it "deletes all keys that are strings" do
      subject['foo'] = 'bar'
      subject[:baz] = 'quux'

      subject.symbolize_keys!
      expect(subject).to_not have_key('foo')
    end

    it "replaces the deleted keys with interned strings" do
      subject['foo'] = 'bar'
      subject[:baz] = 'quux'

      subject.symbolize_keys!
      expect(subject[:foo]).to eq 'bar'
    end

    it "raises an error if there is an existing symbol for a given string key" do
      subject['foo'] = 'bar'
      subject[:foo] = 'quux'

      expect {
        subject.symbolize_keys!
      }.to raise_error(TypeError, /An existing interned key/)
    end

    it "does not modify existing symbol entries" do
      subject['foo'] = 'bar'
      subject[:baz] = 'quux'

      subject.symbolize_keys!
      expect(subject[:baz]).to eq 'quux'
    end

    it "does not modify keys that are not strings or symbols" do
      key = %w[foo]
      subject[key] = 'bar'

      subject.symbolize_keys!
      expect(subject[key]).to eq 'bar'
    end
  end
end
