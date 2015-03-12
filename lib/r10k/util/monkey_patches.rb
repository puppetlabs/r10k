if !Symbol.instance_methods.include?(:<=>)
  class Symbol
    # Ruby 1.8.7 does not define #<=>, which subsequently breaks Enumerable#sort
    # when sorting an array of symbols.
    #
    # @see https://github.com/puppetlabs/r10k/issues/310
    def <=>(other)
      self.to_s <=> other.to_s if other.is_a?(Symbol)
    end
  end
end
