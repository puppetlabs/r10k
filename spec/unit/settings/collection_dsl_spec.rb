require 'spec_helper'
require 'r10k/settings/collection_dsl'

describe R10K::Settings::CollectionDSL do

  it 'creates a collection maker for inheriting classes' do
    expect(Class.new(described_class).maker).to be_a_kind_of R10K::Settings::CollectionMaker
  end

  it 'creates separate collection makers for each inheriting class' do
    class1 = Class.new(described_class)
    class2 = Class.new(described_class)
    expect(class1.maker).to_not eq class2.maker
  end

  describe 'generating a collection' do
    let(:nested_collection_class) do
      k = Class.new(described_class)
      k.class_eval do
        def initialize
          super(:nested)
        end

        add_setting(
          :nestedsetting,
          {
            :desc => 'some nested setting'
          }
        )
      end
      k
    end

    let(:base_collection_class) do
      k = Class.new(described_class)
      k.class_eval do
        def initialize
          super(:base)
        end

        add_setting(
          :topsetting,
          {
            :desc => 'some top level setting'
          }
        )
      end
      # We can't access nested_collection_class inside of the above
      # #class_eval'd class, but collection settings can only be set in the
      # #class_eval scope. To get around that we just use a send to add the
      # collection in the scope that has access.
      k.send(:add_collection, nested_collection_class)
      k
    end

    subject { base_collection_class.new }

    it 'creates all supplied definitions' do
      expect(subject.definitions.size).to eq 1
      defn = subject.definitions[:topsetting]
      expect(defn.desc).to eq 'some top level setting'
    end

    it 'creates all nested collections' do
      expect(subject.collections.size).to eq 1
      nested = subject.collections[:nested]
      expect(nested).to be_a_kind_of(nested_collection_class)
    end
  end
end
