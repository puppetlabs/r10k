RSpec::Matchers.define :exit_with do |expected|
  actual = nil
  match do |block|
    begin
      block.call
    rescue SystemExit => e
      actual = e.status
    end
    actual and actual == expected
  end
  failure_message_for_should do |block|
    "expected exit with code #{expected} but " +
      (actual.nil? ? " exit was not called" : "we exited with #{actual} instead")
  end
  failure_message_for_should_not do |block|
    "expected that exit would not be called with #{expected}"
  end
  description do
    "expect exit with #{expected}"
  end
end

