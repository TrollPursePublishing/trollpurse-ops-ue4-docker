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

Stop-Service *docker*

$storageOpts = ,'size=550GB'

$dockerConfig = Get-Content -Path C:\ProgramData\Docker\config\daemon.json -Raw | ConvertFrom-Json
$dockerConfig
if($dockerConfig.'storage-opts' -eq $nul) {
  Add-Member -InputObject $dockerConfig -Name 'storage-opts' -MemberType 'NoteProperty' -Value $storageOpts
} else {
  $dockerConfig.'storage-opts' = $storageOpts
}
$dockerConfig | ConvertTo-Json -depth 100 | Out-File C:\ProgramData\Docker\config\daemon.json

Start-Service *docker*

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
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."   
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
refreshenv

pip --version
pip install ue4-docker
ue4-docker setup
ue4-docker build $engineVersion --no-engine --exclude debug --exclude templates -username $ue4GitUsername -password $ue4GitPersonalAccessToken

#Assume Windows Server 2019
$prereqRepoName = "${repositoryName}ue4/ue4-build-prerequisites:ltsc2019"
$minimalRepoName = "${repositoryName}ue4/ue4-minimal:${engineVersion}-ltsc2019"
$fullRepoName = "${repositoryName}ue4/ue4-full:${engineVersion}-ltsc2019"
$currentMinimalRepoTag = "adamrehn/ue4-minimal:${engineVersion}-ltsc2019"
$currentFullRepoTag = "adamrehn/ue4-full:${engineVersion}-ltsc2019"

docker tag adamrehn/ue4-build-prerequisites:ltsc2019 $prereqRepoName
docker tag $currentMinimalRepoTag $minimalRepoName
docker tag $currentFullRepoTag $fullRepoName

ue4-docker clean --source

docker push $prereqRepoName
docker push $minimalRepoName
docker push $fullRepoName

return $LASTEXITCODE
