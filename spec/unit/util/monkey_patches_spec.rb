require 'spec_helper'
require 'r10k/util/monkey_patches'

describe Symbol, "comparison operator", :if => RUBY_VERSION == '1.8.7' do
  it "returns nil if the other value is incomparable" do
    expect(:aaa <=> 'bbb').to be_nil
  end

  it "returns -1 if the value sorts lower than the compared value" do
    expect(:aaa <=> :bbb).to eq(-1)
  end

  it "returns 0 if the values are equal" do
    expect(:aaa <=> :aaa).to eq(0)
  end

  it "returns 1 if the value sorts higher than the compared value" do
    expect(:bbb <=> :aaa).to eq(1)
  end
end
