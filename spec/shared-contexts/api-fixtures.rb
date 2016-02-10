require 'rspec'

RSpec.shared_context "R10K::API" do
  let(:cachedir) { "/tmp/r10k/cache" }

  let(:modules) do
    [
      { name: "git_module", type: "git", resolved_version: "git_version", },
      { name: "forge_module", type: "forge", resolved_version: "forge_version", },
      { name: "local_module", type: "local", resolved_version: "local_version", },
      { name: "crazy_town", type: "banana", resolved_version: "cavendish", },
    ]
  end

  let(:source) do
    { type: :git }
  end

  let(:envmap) do
    { source: source, modules: modules, fake: true }
  end

  let(:unresolved_forge_modules) do
    [
      { name: 'apache', type: 'forge', source: 'puppetlabs-apache', version: 'unpinned' }, # unpinned and undeployed
      { name: 'stdlib', type: 'forge', source: 'puppetlabs-stdlib', version: 'unpinned', deployed_version: '1.0.0' }, # unpinned but already deployed
      { name: 'mysql', type: 'forge', source: 'puppetlabs-mysql', version: 'latest' }, # track latest
      { name: 'nginx', type: 'forge', source: 'jfryman-nginx', version: '0.2.4' }, # pin to version
      { name: 'concat', type: 'forge', source: 'puppetlabs-concat', version: '1.x' }, # track latest in range
      { name: 'hiera', type: 'forge', source: 'hunner-hiera', version: '>=1.4.0 <1.5.0' }, # track latest in range (alt)
      { name: 'wordpress', type: 'forge', source: 'hunner/wordpress', version: '1.0.0' }, # slash seperated
    ]
  end

  let(:unresolved_git_modules) do
    [
      { name: 'acl', type: 'git', source: 'git://github.com/puppetlabs/puppetlabs-acl', version: '1.1.0' }, # tag
      { name: 'activemq', type: 'git', source: 'git://github.com/puppetlabs/puppetlabs-activemq.git', version: '5126eb7a1da3cc3687f99c5e568aceb87362c7a6' }, # full sha
      { name: 'alternatives', type: 'git', source: 'git://github.com/adrienthebo/puppet-alternatives.git', version: '8f7c2e' }, # short sha
      { name: 'apt', type: 'git', source: 'git://github.com/puppetlabs/puppetlabs-apt.git', version: 'feature_branch' }, # track branch
      { name: 'autosign', type: 'git', source: 'git://github.com/danieldreier/puppet-autosign.git', version: '05461f112af32422a2139a5ebc4e4b5a1bef8aab', deployed_version: '05461f112af32422a2139a5ebc4e4b5a1bef8aab' }, # no-op
    ]
  end

  let(:unresolved_modules) { [ unresolved_forge_modules, unresolved_git_modules ].flatten }

  let(:unresolved_envmap) do
    { source: source, modules: unresolved_modules, fake: true }
  end

  let(:mock_fh) do
    instance_double("IO", write: true, close: true)
  end
end
