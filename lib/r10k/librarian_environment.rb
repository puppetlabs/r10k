require 'librarian/puppet'

module R10K
class LibrarianEnvironment

  attr_reader :environment_root

  def initialize(environment_root)
    @environment_root = environment_root
    @environment = Librarian::Puppet::Environment.new(:pwd => @environment_root)
  end

  def install!
    Librarian::Action::Install.new(@environment, {}).run
  end

end
end