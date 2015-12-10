require 'r10k/settings/container'

module R10K
  module Settings
    module Mixin

      def self.included(klass)
        klass.send(:include, InstanceMethods)
        klass.send(:extend, ClassMethods)
      end

      module InstanceMethods
        # @return [R10K::Settings::Container] A settings container for the given instance.
        def settings
          @settings ||= R10K::Settings::Container.new(self.class.settings)
        end
      end

      module ClassMethods
        # Define a setting and optional default on the extending class.
        #
        # @param key [Symbol]
        # @param default [Object]
        #
        # @return [void]
        def def_setting_attr(key, default = nil)
          defaults.add_valid_key(key)
          defaults[key] = default if default
        end

        # A singleton settings container for storing immutable default configuration
        # on the extending class.
        #
        # @return [R10K::Settings::Container]
        def defaults
          @defaults ||= R10K::Settings::Container.new
        end

        # A singleton settings container for storing manual setting configurations
        # on the extending class.
        #
        # @return [R10K::Settings::Container]
        def settings
          @settings ||= R10K::Settings::Container.new(defaults)
        end

        # Allow subclasses to use the settings of the parent class as default values
        #
        # @return [void]
        def inherited(subclass)
          subclass.instance_eval do
            @settings = R10K::Settings::Container.new(superclass.settings)
          end
        end
      end
    end
  end
end
