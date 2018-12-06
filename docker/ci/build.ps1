$ErrorActionPreference = 'Stop'

function Get-CurrentDirectory
{
  $thisName = $MyInvocation.MyCommand.Name
  [IO.Path]::GetDirectoryName((Get-Content function:$thisName).File)
}

function Get-ContainerVersion
{
  # shallow repositories need to pull remaining code to `git describe` correctly
  if (Test-Path "$(git rev-parse --git-dir)/shallow")
  {
    git pull --unshallow
  }

  # tags required for versioning
  git fetch origin 'refs/tags/*:refs/tags/*'
  (git describe) -replace '-.*', ''
}

# installs gems for build and test and grabs base images
function Invoke-ContainerBuildSetup
{
  Push-Location (Get-CurrentDirectory)
  bundle install --path '.bundle/gems'
  bundle exec puppet-docker update-base-images ubuntu:16.04
  Pop-Location
}

function Build-Container($Name, $Repository = '127.0.0.1', $Version = (Get-ContainerVersion))
{
  Push-Location (Join-Path (Get-CurrentDirectory) '..')
  bundle exec puppet-docker local-lint $Name
  bundle exec puppet-docker build $Name --no-cache --repository $Repository --version $Version --no-latest --build-arg namespace=$Repository
  Pop-Location
}

function Invoke-ContainerTest($Name, $Repository = '127.0.0.1', $Version = (Get-ContainerVersion))
{
  Push-Location (Join-Path (Get-CurrentDirectory) '..')
  bundle exec puppet-docker spec $Name --image "$Repository/${Name}:$Version"
  Pop-Location
}

# removes any temporary containers / images used during builds
function Clear-ContainerBuilds
{
  docker container prune --force
  docker image prune --filter "dangling=true" --force
}
