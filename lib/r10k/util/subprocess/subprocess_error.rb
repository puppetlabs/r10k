require 'r10k/errors'
require 'r10k/util/subprocess'
require 'r10k/util/setopts'

class R10K::Util::Subprocess::SubprocessError < R10K::Error

  # !@attribute [r] result
  #   @return [R10K::Util::Subprocess::Result]
  attr_reader :result

  include R10K::Util::Setopts

  def initialize(mesg, options = {})
    super
    setopts(options, {:result => true})
  end

  def message
    msg = []
    msg << "#{super}:"
    msg << @result.format
    msg.join("\n")
  end
end
