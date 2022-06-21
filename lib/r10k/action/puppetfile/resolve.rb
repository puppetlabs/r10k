require 'r10k/action/base'
require 'r10k/content_synchronizer'
require 'r10k/errors/formatting'
require 'r10k/module_loader/puppetfile'
require 'r10k/util/cleaner'
require 'puppetfile-resolver'
require 'puppetfile-resolver/puppetfile/parser/r10k_eval'

module R10K
  module Action
    module Puppetfile
      class Resolve < R10K::Action::Base

        def call
          begin
            @output ||= 'Puppetfile'
            @source ||= "#{@output}.src"

            unless @force
              if File.exist? @output
                logger.error "Pass --force to overwrite existing file: #{@output}"
                return false
              end
            end

            content    = File.read(@source)
            puppetfile = PuppetfileResolver::Puppetfile::Parser::R10KEval.parse(content)

            # Make sure the Puppetfile is valid
            unless puppetfile.valid?
              logger.error 'Puppetfile source is not valid'
              puppetfile.validation_errors.each { |err| logger.error err }
              return false
            end

            resolver = PuppetfileResolver::Resolver.new(puppetfile, nil)
            result   = resolver.resolve(strict_mode: true)

            # Output resolution validation errors
            result.validation_errors.each { |err| logger.warn err}

            File.open(@output, "w+") do |file|
              # copy over the existing Puppetfile, then add resolved dependencies below
              file.write puppetfile.content
              file.write "\n####### resolved dependencies #######\n"

              result.dependency_graph.each do |dep|
                # ignore the original modules, they're already in the lockfile
                next if puppetfile.modules.find {|mod| mod.name == dep.name}

                mod = dep.payload
                next unless mod.is_a? PuppetfileResolver::Models::ModuleSpecification

                file.write "mod '#{dep.payload.owner}-#{dep.payload.name}', '#{dep.payload.version}'\n"
              end
            end
          end

          logger.warn "Please inspect #{@output} and the modules it declares to ensure you know what you are deploying in your infrastructure."
        end

        private

        def allowed_initialize_opts
          super.merge(root: :self, output: :self, source: :self, force: :self )
        end
      end
    end
  end
end
