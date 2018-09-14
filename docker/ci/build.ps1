$ErrorActionPreference = 'Stop'

function Get-CurrentDirectory
{
  $thisName = $MyInvocation.MyCommand.Name
  [IO.Path]::GetDirectoryName((Get-Content function:$thisName).File)
}

# installs gems for build and test and grabs base images
function Invoke-ContainerBuildSetup
{
  Push-Location (Get-CurrentDirectory)
  bundle install --path '.bundle/gems'
  bundle exec puppet-docker update-base-images ubuntu:16.04
  Pop-Location
}
