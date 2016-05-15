Puppet::Type.newtype(:logstash_plugin) do
  @doc = 'Plugin installation type'

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'An arbitrary name used as the identity of the resource.'
  end

  newparam(:version) do
    desc 'Plugin version'
  end
end
