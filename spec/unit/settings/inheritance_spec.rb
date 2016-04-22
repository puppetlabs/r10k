require 'spec_helper'
require 'r10k/settings/collection'
require 'r10k/settings/definition'

RSpec.describe 'R10K::Settings inheritance' do
  subject do
    R10K::Settings::Collection.new(:parent_settings, [
      R10K::Settings::Definition.new(:banana, {
        :default => 'cavendish',
      }),

      R10K::Settings::Collection.new(:child_settings, [
        R10K::Settings::Definition.new(:banana, {
          :default => :inherit,
        }),
      ]),
    ])
  end

  describe "child settings" do
    let(:setting) { subject[:child_settings][:banana] }

    context "when child value is not set" do
      it "should resolve to default value from parent" do
        expect(setting.value).to be_nil
        expect(setting.resolve).to eq 'cavendish'
      end
    end

    context "when child value is set" do
      before(:each) { setting.assign('gros michel') }

      it "should resolve to child value" do
        expect(setting.resolve).to eq 'gros michel'
      end
    end
  end
end
