require 'r10k/settings/definition'

module R10K
  module Settings
    # Define a setting for setting filesystem paths and validating that paths are
    # readable or writable.
    #
    # @example Ensuring a path is readable and writable
    #   defn = R10K::Settings::PathDefinition.new(:mypath, :readable => true, :writable => true)
    #   defn.set("/some/unreadable/path") #=> ArgumentError, "/some/unreadable/path is not readable"
    #   defn.set("/proc/cmdline") #=> ArgumentError, "/some/unreadable/path is not writable"
    #
    class PathDefinition < R10K::Settings::Definition

      # @!attribute [r] readable
      #   @return [true, false] If the path should be validated as readable when set
      attr_reader :readable

      # @!attribute [r] writable
      #   @return [true, false] If the path should be validated as writable when set
      attr_reader :writable

      def set(newvalue)
        if @readable && !File.readable?(newvalue)
          raise ArgumentError, "#{newvalue} is not readable"
        end
        if @writable && !File.writable?(newvalue)
          raise ArgumentError, "#{newvalue} is not writable"
        end
        super
      end

      private

      def allowed_initialize_opts
        super.merge(:readable => true, :writable => true)
      end
    end
  end
end
