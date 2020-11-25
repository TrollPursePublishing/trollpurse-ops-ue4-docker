param (
    [string]$accountId,
    [string]$region,
    [string]$repositoryName,
    [string]$engineVersion,
    [string]$ue4GitUsername,
    [string]$ue4GitPersonalAccessToken
)

trap
{
  Write-Output $_
  exit 1
}

# Install Python, Required for ue4-docker
Write-Output "Installing Python 3 latest"
Set-ExecutionPolicy Bypass -Scope Process -Force;
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
	'https://chocolatey.org/install.ps1'
))

# Authenticate with ECR
Write-Output "Authenticate with ECR..."
Invoke-Expression -Command (Get-ECRLoginCommand).Command

choco install -y python --version=3.8.0
choco install -y git
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."   
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
refreshenv

python --version
pip --version
pip install git+https://github.com/TrollPursePublishing/ue4-docker.git@550_Windows_Patch

ue4-docker info
ue4-docker setup
ue4-docker build $engineVersion --no-engine --exclude debug --exclude templates -username $ue4GitUsername -password $ue4GitPersonalAccessToken

#Assume Windows Server 2019
$fullRepoName = "${repositoryName}:${engineVersion}-ltsc2019"
$currentFullRepoTag = "adamrehn/ue4-full:${engineVersion}-ltsc2019"

docker tag $currentFullRepoTag $fullRepoName

ue4-docker clean --source

docker push $fullRepoName

return $LASTEXITCODE
