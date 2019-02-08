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

function Lint-Dockerfile($Path)
{
  hadolint --ignore DL3008 --ignore DL3018 --ignore DL4000 --ignore DL4001 $Path
}

function Build-Container(
  $Namespace = 'puppet',
  $Version = (Get-ContainerVersion),
  $Vcs_ref = $(git rev-parse HEAD))
{
  Push-Location (Join-Path (Get-CurrentDirectory) '..')

  $build_date = (Get-Date).ToUniversalTime().ToString('o')
  $docker_args = @(
    '--pull',
    '--build-arg', "vcs_ref=$Vcs_ref",
    '--build-arg', "build_date=$build_date",
    '--build-arg', "version=$Version",
    '--file', "r10k/Dockerfile",
    '--tag', "$Namespace/r10k:$Version"
  )

  docker build $docker_args r10k

  Pop-Location
}

function Invoke-ContainerTest(
  $Namespace = 'puppet',
  $Version = (Get-ContainerVersion))
{
  Push-Location (Join-Path (Get-CurrentDirectory) '..')

  bundle install --path .bundle/gems
  $ENV:PUPPET_TEST_DOCKER_IMAGE = "$Namespace/r10k:$Version"
  bundle exec rspec r10k/spec

  Pop-Location
}

# removes any temporary containers / images used during builds
function Clear-ContainerBuilds
{
  docker container prune --force
  docker image prune --filter "dangling=true" --force
}
