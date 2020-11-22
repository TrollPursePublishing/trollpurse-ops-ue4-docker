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

# Set Confiugrations
Set-Variable UE4DOCKER_TAG_NAMESPACE=ue4

choco install -y python --version=3.8.0
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."   
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
refreshenv

pip --version
pip install ue4-docker
ue4-docker setup
ue4-docker build $engineVersion --no-engine --exclude debug --exclude templates -username $ue4GitUsername -password $ue4GitPersonalAccessToken
ue4-docker clean --source
docker tag ue4/ue4-full:$engineVersion $repositoryName
docker push $repositoryName

return $LASTEXITCODE
