$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', '..'))

Puppet::Type.type(:logstash_plugin).provide(:lsplugin) do
  desc "A provider for the resource type `logstash_plugin`,
        which handles plugin installation"

  mk_resource_methods

  os = Facter.value('osfamily')
  if os == 'OpenBSD'
    commands :plugin => '/usr/local/logstash/bin/plugin'
    commands :ls => '/usr/local/logstash/bin/logstash'
    commands :javapathhelper => '/usr/local/bin/javaPathHelper'
  else
    commands :plugin => '/opt/logstash/bin/plugin'
    commands :plugin5x => '/opt/logstash/bin/logstash-plugin'
    commands :ls => '/opt/logstash/bin/logstash'
  end

  def plugin_exists?(plugin)
    begin
      plugin = plugin(['list', '--verbose', plugin]) if is2x?
      plugin = plugin5x(['list', '--verbose', plugin]) if is5x?
    rescue Puppet::ExecutionFailure
      return false
    end
    name, version = plugin.scan(/(\w+\-\w+\-\w+)? \((\d+\.\d+\.\d+(?:\-\S+)?)\)/).first
    { :name => name, :version => version }
  end

  def exists?
    if plugin_hash = plugin_exists?(@resource[:name]) # rubocop:disable Lint/AssignmentInCondition, Style/GuardClause
      unless @resource[:version].nil?
        Puppet.debug "Expected version #{@resource[:version]} got #{plugin_hash[:version]}"
        return @resource[:version] == plugin_hash[:version]
      end
      return true
    else
      return false
    end
  end

  def install2x
    commands = [@resource[:name]]
    commands
  end

  def create
    ls_version
    commands = []
    commands << 'install'
    commands << ['--version', @resource[:version].to_s] if @resource[:version]
    commands << install2x if is2x? || is5x?
    Puppet.debug "Commands: #{commands.inspect}"

    retry_count = 3
    retry_times = 0
    begin
      plugin(*commands) if is2x?
      plugin5x(*commands) if is5x?
    rescue Puppet::ExecutionFailure
      retry_times += 1
      debug("Failed to install plugin. Retrying... #{retry_times} of #{retry_count}")
      retry if retry_times < retry_count
    end
  end

  def destroy
    plugin(['uninstall', @resource[:name]]) if is2x?
    plugin5x(['uninstall', @resource[:name]]) if is5x?
  end

  def ls_version
    return @ls_version if @ls_version
    java_save = ENV['JAVA_HOME']

    os = Facter.value('osfamily')
    ENV['JAVA_HOME'] = javapathhelper('-h', 'logstash').chomp if os == 'OpenBSD'
    begin
      version = ls('--version')
    rescue
      ENV['JAVA_HOME'] = java_save if java_save
      raise "Unknown Logstash version. Got #{version.inspect}"
    ensure
      ENV['JAVA_HOME'] = java_save if java_save
      @ls_version = version.scan(/\d+\.\d+\.\d+(?:\-\S+)?/).first
      debug "Found Logstash version #{@ls_version}"
    end
  end

  def is2x?
    (Puppet::Util::Package.versioncmp(@ls_version, '2.0.0') >= 0) && (Puppet::Util::Package.versioncmp(@ls_version, '3.0.0') < 0)
  end

  def is5x?
    (Puppet::Util::Package.versioncmp(@ls_version, '5.0.0') >= 0) && (Puppet::Util::Package.versioncmp(@ls_version, '6.0.0') < 0)
  end
end
