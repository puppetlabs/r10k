
module R10K; end
module R10K::Util; end

module R10K::Util::Interp

  # Interpolate a string with a given scope
  #
  # @param [String] string
  # @param [Hash]   scope
  #
  # @return [String]
  def interpolate_string(string, scope)

    interp = string.clone

    while (matchdata = interp.match /%\{.+?\}/)
      var_name = matchdata[1].intern
      var_data = scope[var_name]
      interp.gsub!(/%\{#{var_name}\}/, var_data)
    end

    interp
  end
end
