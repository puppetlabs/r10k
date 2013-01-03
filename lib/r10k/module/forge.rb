require 'r10k'
require 'r10k/module'

require 'systemu'
require 'semver'
require 'json'

class R10K::Module::Forge < R10K::Module

  def self.implements(name, args)
    args.is_a? String and SemVer.valid?(args)
  end

  def initialize(name, path, args)
    super

    @full_name = name

    @owner, @name = name.split('/')
    @version = SemVer.new(@args)
  end

  def sync!(options = {})
    return if insync?

    if File.exist? metadata_path
      cmd = []
      cmd << 'upgrade'
      cmd << "--version=#{@version}"
      cmd << "--ignore-dependencies"
      cmd << @full_name
      pmt cmd
    else
      cmd = []
      cmd << 'install'
      cmd << "--version=#{@version}"
      cmd << "--ignore-dependencies"
      cmd << @full_name
      pmt cmd
    end

  end

  def full_path
    File.join(@path, @name)
  end

  private

  def insync?
    current_version = SemVer.new(metadata['version'])
  rescue
    false
  end

  def metadata
    JSON.parse(File.read(metadata_path))
  end

  def metadata_path
    File.join(full_path, 'metadata.json')
  end

  def pmt(args)

    cmd = "puppet module --modulepath '#{@path}' #{args.join(' ')}"

    puts cmd
    status, stdout, stderr = systemu(cmd)

    if status == 0
      puts "YAY!".cyan
    else
      puts "NO!".red
    end

    #Shellter.run('puppet' ,args.join(' '))
    #result = Shellter.run('puppet' ,args.join(' '))
    #if result.success?
    #  stderr = result.stderr.read
    #  stdout = result.stdout.read

    #  #puts stdout.blue unless stdout.empty?
    #  #puts stderr.red  unless stderr.empty?

    #  stdout
    #else
    #  raise RuntimeError, "Command #{result.last_command.inspect} exited with value #{result.exit_code}"
    #end
  end
end
