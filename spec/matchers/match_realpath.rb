RSpec::Matchers.define :match_realpath do |expected|

  match do |actual|
    actual == expected || realpath(actual) == realpath(expected)
  end

  failure_message do |actual|
    "expected that #{actual} would have a real path of #{expected}"
  end

  failure_message_when_negated do |actual|
    "expected that #{actual} would not have a real path of #{expected}"
  end

  def realpath(path)
    Pathname.new(path).realpath.to_s
  end
end
