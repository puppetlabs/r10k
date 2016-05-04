require 'r10k/errors'
require 'r10k/settings/collection'

module R10K
  module Settings
    module Helpers
      def self.included(klass)
        klass.send(:include, InstanceMethods)
        klass.send(:extend, ClassMethods)
      end

      module InstanceMethods
        # Assign a parent collection to this setting. Parent may only be
        # assigned once.
        #
        # @param new_parent [R10K::Settings::Collection] Parent collection
        def parent=(new_parent)
          unless @parent.nil?
            raise R10K::Error.new("#{self.class} instances cannot be reassigned to a new parent.")
          end

          unless new_parent.is_a?(R10K::Settings::Collection) || new_parent.is_a?(R10K::Settings::List)
            raise R10K::Error.new("#{self.class} instances may only belong to a settings collection or list.")
          end

          @parent = new_parent
        end

        def parent
          @parent
        end
      end

      module ClassMethods
      end
    end
  end
end
