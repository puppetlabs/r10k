require 'r10k/util/subprocess'
require 'json'
require 'yaml'

class R10K::Source::Exec < R10K::Source::Hash
  R10K::Source.register(:exec, self)

  def initialize(name, basedir, options = {})
    unless @command = options[:command]
      raise ConfigError, _('Environment source %{name} missing required parameter: command') % {name: name}
    end

    # We haven't set the environments option yet. We will do that by
    # overloading the #environments method.
    super(name, basedir, options)
  end

  def environments
    if @environments.nil?
      set_environments_hash(run_environments_command)
      super
    end
    @environments
  end

  def run_environments_command
    subproc = R10K::Util::Subprocess.new([@command])
    subproc.raise_on_fail = true
    subproc.logger = self.logger
    procresult = subproc.execute

    begin
      environments = JSON.parse(procresult.stdout)
    rescue JSON::ParserError => json_err
      begin
        environments = YAML.load(procresult.stdout)
      rescue Psych::SyntaxError => yaml_err
        raise R10K::Error, _("Error parsing command output for exec source %{name}:\n" \
                             "Not valid JSON: %{j_msg}\n" \
                             "Not valid YAML: %{y_msg}\n" \
                             "Stdout:\n%{out}") % {name: name, j_msg: json_err.message, y_msg: yaml_err.message, out: procresult.stdout}
      end
    end

    unless R10K::Source::Hash.valid_environments_hash?(environments)
      raise R10K::Error, _("Environment source ${name} command %{cmd} did not return valid environment data.\n" \
                           'Returned: %{data}') % {name: name, cmd: command, data: environments}
    end

    # Return the resulting environments hash
    environments
  end
end
