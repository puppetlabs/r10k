require 'spec_helper'
require 'r10k/action/visitor'
require 'r10k/logging'

describe R10K::Action::Visitor do
  let(:visitor_class) do
    Class.new do
      include R10K::Action::Visitor
      include R10K::Logging
      attr_accessor :trace

      def visit_error(other)
        raise ArgumentError, "no soup for you"
      end
    end
  end

  subject { visitor_class.new }

  it "dispatches visit invocations to the type specific method" do
    expect(subject).to receive(:visit_sym).with(:hi)
    subject.visit(:sym, :hi)
  end

  describe "when a visit_ method raises an error" do

    [true, false].each do |trace|
      msg = trace ? "a" : "no"
      it "logs the error with #{msg} backtrace when trace is #{trace}" do
        subject.trace = trace
        expect(R10K::Errors::Formatting).to(
          receive(:format_exception).with(instance_of(ArgumentError), trace)
        ).and_return("errmsg")
        expect(subject.logger).to receive(:error).with('errmsg')
        subject.visit(:error, :hi)
      end
    end
  end
end
