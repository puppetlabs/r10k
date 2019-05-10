require 'thread'
require 'pathname'
require 'r10k/module'
require 'r10k/util/purgeable'
require 'r10k/errors'

module R10K
class Puppetfile
  # Defines the data members of a Puppetfile

  include R10K::Settings::Mixin

  def_setting_attr :pool_size, 1

  include R10K::Logging

  # @!attribute [r] forge
  #   @return [String] The URL to use for the Puppet Forge
  attr_reader :forge

  # @!attribute [r] modules
  #   @return [Array<R10K::Module>]
  attr_reader :modules

  # @!attribute [r] basedir
  #   @return [String] The base directory that contains the Puppetfile
  attr_reader :basedir

  # @!attribute [r] moduledir
  #   @return [String] The directory to install the modules #{basedir}/modules
  attr_reader :moduledir

  # @!attrbute [r] puppetfile_path
  #   @return [String] The path to the Puppetfile
  attr_reader :puppetfile_path

  # @!attribute [rw] environment
  #   @return [R10K::Environment] Optional R10K::Environment that this Puppetfile belongs to.
  attr_accessor :environment

  # @!attribute [rw] force
  #   @return [Boolean] Overwrite any locally made changes
  attr_accessor :force

  # @param [String] basedir
  # @param [String] moduledir The directory to install the modules, default to #{basedir}/modules
  # @param [String] puppetfile_path The path to the Puppetfile, default to #{basedir}/Puppetfile
  # @param [String] puppetfile_name The name of the Puppetfile, default to 'Puppetfile'
  # @param [Boolean] force Shall we overwrite locally made changes?
  def initialize(basedir, moduledir = nil, puppetfile_path = nil, puppetfile_name = nil, force = nil )
    @basedir         = basedir
    @force           = force || false
    @moduledir       = moduledir  || File.join(basedir, 'modules')
    @puppetfile_name = puppetfile_name || 'Puppetfile'
    @puppetfile_path = puppetfile_path || File.join(basedir, @puppetfile_name)

    logger.info _("Using Puppetfile '%{puppetfile}'") % {puppetfile: @puppetfile_path}

    @modules = []
    @managed_content = {}
    @forge   = 'forgeapi.puppetlabs.com'

    @loaded = false
  end

  def load
    if File.readable? @puppetfile_path
      self.load!
    else
      logger.debug _("Puppetfile %{path} missing or unreadable") % {path: @puppetfile_path.inspect}
    end
  end

  def load!
    begin
      logger.debug "Attempting to parse the AST directly"

      parser = R10K::Puppetfile::Parser.new(self)
      parser.parse(puppetfile_contents)

    rescue R10K::Error => e
      logger.debug "Falling back to eval'ing the Puppetfile"

      dsl = R10K::Puppetfile::DSL.new(self)
      dsl.instance_eval(puppetfile_contents, @puppetfile_path)
    end
    
    validate_no_duplicate_names(@modules)
    @loaded = true
  rescue SyntaxError, LoadError, ArgumentError, NameError => e
    raise R10K::Error.wrap(e, _("Failed to evaluate %{path}") % {path: @puppetfile_path})
  end

  # @param [Array<String>] modules
  def validate_no_duplicate_names(modules)
    dupes = modules
            .group_by { |mod| mod.name }
            .select { |_, v| v.size > 1 }
            .map(&:first)
    unless dupes.empty?
      msg = _('Puppetfiles cannot contain duplicate module names.')
      msg += ' '
      msg += _("Remove the duplicates of the following modules: %{dupes}" % { dupes: dupes.join(' ') })
      raise R10K::Error.new(msg)
    end
  end

  # @param [String] forge
  def set_forge(forge)
    @forge = forge
  end

  # @param [String] moduledir
  def set_moduledir(moduledir)
    @moduledir = if Pathname.new(moduledir).absolute?
      moduledir
    else
      File.join(basedir, moduledir)
    end
  end

  # @param [String] name
  # @param [*Object] args
  def add_module(name, args)
    if args.is_a?(Hash) && install_path = args.delete(:install_path)
      install_path = resolve_install_path(install_path)
      validate_install_path(install_path, name)
    else
      install_path = @moduledir
    end

    # Keep track of all the content this Puppetfile is managing to enable purging.
    @managed_content[install_path] = Array.new unless @managed_content.has_key?(install_path)

    mod = R10K::Module.new(name, install_path, args, @environment)

    @managed_content[install_path] << mod.name
    @modules << mod
  end

  include R10K::Util::Purgeable

  def managed_directories
    self.load unless @loaded

    @managed_content.keys
  end

  # Returns an array of the full paths to all the content being managed.
  # @note This implements a required method for the Purgeable mixin
  # @return [Array<String>]
  def desired_contents
    self.load unless @loaded

    @managed_content.flat_map do |install_path, modnames|
      modnames.collect { |name| File.join(install_path, name) }
    end
  end

  def purge_exclusions
    exclusions = managed_directories

    if environment && environment.respond_to?(:desired_contents)
      exclusions += environment.desired_contents
    end

    exclusions
  end

  def accept(visitor)
    pool_size = self.settings[:pool_size]
    if pool_size > 1
      concurrent_accept(visitor, pool_size)
    else
      serial_accept(visitor)
    end
  end

  private

  def serial_accept(visitor)
    visitor.visit(:puppetfile, self) do
      modules.each do |mod|
        mod.accept(visitor)
      end
    end
  end

  def concurrent_accept(visitor, pool_size)
    logger.debug _("Updating modules with %{pool_size} threads") % {pool_size: pool_size}
    mods_queue = modules_queue(visitor)
    thread_pool = pool_size.times.map { visitor_thread(visitor, mods_queue) }
    thread_pool.each(&:join)
  end

  def modules_queue(visitor)
    Queue.new.tap do |queue|
      visitor.visit(:puppetfile, self) do
        modules.each { |mod| queue << mod }
      end
    end
  end

  def visitor_thread(visitor, mods_queue)
    Thread.new do
      begin
        while mod = mods_queue.pop(true) do mod.accept(visitor) end
      rescue ThreadError => e
        logger.error _("Thread error during concurrent module deploy: %{message}") % {message: e.message}
        Thread.exit
      end
    end
  end

  def puppetfile_contents
    File.read(@puppetfile_path)
  end

  def resolve_install_path(path)
    pn = Pathname.new(path)

    unless pn.absolute?
      pn = Pathname.new(File.join(basedir, path))
    end

    # .cleanpath is as good as we can do without touching the filesystem.
    # The .realpath methods will also choke if some of the intermediate
    # paths are missing, even though we will create them later as needed.
    pn.cleanpath.to_s
  end

  def validate_install_path(path, modname)
    real_basedir = Pathname.new(basedir).cleanpath.to_s

    unless /^#{Regexp.escape(real_basedir)}.*/ =~ path
      raise R10K::Error.new("Puppetfile cannot manage content '#{modname}' outside of containing environment: #{path} is not within #{real_basedir}")
    end

    true
  end

  class Parser
    # A Puppetfile parser that does not require eval'ing Ruby code
    # 
    # @api private

    def initialize(librarian)
      @librarian = librarian
    end

    def parse(puppetfile)
      root = nil
      begin
        root = RubyVM::AbstractSyntaxTree.parse(puppetfile)
      rescue NameError => e
        # When run on Ruby 2.6 or greater, this will parse the Puppefile directly.
        # See https://docs.ruby-lang.org/en/trunk/RubyVM/AbstractSyntaxTree.html for more information.
        raise R10K::Error.new("Cannot parse Puppetfile directly on Ruby version #{RUBY_VERSION}")
      end
      traverse(root)
    end

    def traverse(node)
      begin
        if node.type == :FCALL
          name = node.children.first
          args = node.children.last.children.map do |item|
            next if item.nil?

            case item.type
            when :HASH
              Hash[*item.children.first.children.compact.map {|n| n.children.first }]
            else
              item.children.first
            end
          end.compact
          
          case name
          when :mod
            mod = args.shift
            if args.empty? 
              @librarian.add_module(mod, nil)
            else
              @librarian.add_module(mod, *args)
            end            
          when :forge
            @librarian.set_forge(args.shift)
          when :moduledir
            @librarian.set_moduledir(args.shift)
          when :incl
            arg = args.shift
            
            if Pathname.new(arg).absolute?
              path = arg
            else
              path = File.join(File.dirname(@librarian.puppetfile_path), arg)
            end

            parse(File.read(path))
          else
            # Should we log unexpected Ruby code?
          end
        end
        
        node.children.each do |n|
          next unless n.is_a? RubyVM::AbstractSyntaxTree::Node

          traverse(n)
        end
      rescue => e
        puts e.message
      end
    end
  end

  class DSL
    # A barebones implementation of the Puppetfile DSL
    #
    # @api private

    def initialize(librarian)
      @librarian = librarian
    end

    def mod(name, args = nil)
      @librarian.add_module(name, args)
    end

    def forge(location)
      @librarian.set_forge(location)
    end

    def moduledir(location)
      @librarian.set_moduledir(location)
    end

    def method_missing(method, *args)
      raise NoMethodError, _("unrecognized declaration '%{method}'") % {method: method}
    end
  end
end
end
