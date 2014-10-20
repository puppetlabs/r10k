RSpec::Matchers.define :exit_with do |expected|

  supports_block_expectations

  match do |block|
    actual = nil
    begin
      block.call
    rescue SystemExit => e
      actual = e.status
    end
    actual and actual == expected
  end

  failure_message do |actual|
    "expected exit with code #{expected} but " +
      (actual.nil? ? " exit was not called" : "we exited with #{actual} instead")
  end

  failure_message_when_negated do |actual|
    "expected that exit would not be called with #{expected}"
  end

  description do
    "expect exit with #{expected}"
  end
end

