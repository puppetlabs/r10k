require 'spec_helper'
require 'r10k/settings/collection_maker'

describe R10K::Settings::CollectionMaker do
  describe '#add_setting' do
    it 'stores the setting name and options' do
      subject.add_setting(:somename, :desc => 'some setting', :default => true)
      expect(subject.stored_definitions).to eq([[:somename, {:desc => 'some setting', :default => true}]])
    end
  end

  describe '#definitions' do
    it 'creates a Definition class for each stored definition' do
      subject.add_setting(:somename, :desc => 'some setting', :default => true)
      defn = subject.definitions.first

      expect(defn.name).to eq :somename
      expect(defn.desc).to eq 'some setting'
      expect(defn.default).to eq true
    end

    it 'uses a custom Definition class if the :type option is given' do
      subject.add_setting(
        :enumsetting,
        {
          :desc => 'some enum setting',
          :type => R10K::Settings::EnumDefinition,
          :enum => %w[one two three],
          :default => 'two',
        }
      )

      defn = subject.definitions.first

      expect(defn.name).to eq :enumsetting
      expect(defn.desc).to eq 'some enum setting'
      expect(defn.enum).to eq %w[one two three]
      expect(defn.default).to eq 'two'
    end
  end

  describe '#add_collection' do
    let(:collection_class) { double('collection_class') }

    it 'stores a copy of the collection class' do
      subject.add_collection(collection_class)
      expect(subject.stored_collections).to eq([collection_class])
    end
  end

  describe '#collections' do
    let(:collection_instance) { double('collection instance') }
    let(:collection_class) { double('collection class', :new => collection_instance) }
    it 'creates an instance for each stored collection' do
      subject.add_collection(collection_class)
      expect(subject.collections).to eq([collection_instance])
    end
  end
end
