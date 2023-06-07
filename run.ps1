# Powershell

<# Copyright (c) 2022 IAR Systems AB
 #
 # run.ps1 - Run a container with the IAR Build Tools
 # 
 # See LICENSE for detailed license information
 #>

param(
  [parameter(Mandatory=$true)]
  # iarsystems/bx<package>:<version>
  [String]${PkgNameVersion}
)

${ScriptPath} = Split-Path $PSCommandPath -Parent
${PkgName} = ${PkgNameVersion}.Split("/")[-1].Split(":")[0]
${PkgVersion} = ${PkgNameVersion}.Split(":")[-1]

${DockerImageList} = docker images --filter reference=iarsystems/${PkgName}":"${PkgVersion} -q --format "{{.Repository}}:{{.Tag}}"
Write-Output ${DockerImageList}

if (${DockerImageList} -eq $null) {
  Write-Output "ERROR: image ${PkgName}`:${PkgVersion} not found."
}

Write-Output "-- Running a Docker container for ${PkgName}-${PkgVersion}..."
$CurrentLocation = Get-Location
$ContainerID = docker run --detach `
                          --hostname $env:ComputerName `
                          --tty `
                          --volume LMS2`:/usr/local/etc/IARSystems `
                          --volume $CurrentLocation`:/build `
                          ${PkgNameVersion}

Write-Output "-- The working directory is $CurrentLocation."
Write-Output " "

$ImageAliases = "${ScriptPath}\aliases-set.ps1"
$args = @()
$args += $ContainerID
Invoke-Expression "$ImageAliases $args"
