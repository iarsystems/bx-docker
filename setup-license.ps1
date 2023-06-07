# Powershell

<# Copyright (c) 2022 IAR Systems AB
 #
 # setup-license.ps1 - License configuration for the bx-docker images
 # 
 # See LICENSE for detailed license information
 #>

param(
  [parameter(Mandatory=$true)]
  # DockerImage
  [String]${global:PkgNameVersion},
  # LMS2 server IP
  [String]${global:lms2ip}
)

# Check for any existing LMS2 Docker Volume
${BxLMS2Volume} = docker volume ls | select-string LMS2
if (${BxLMS2Volume} -eq $False) {
  Write-Output "-- setup-license: Creating a Docker Volume for LMS2..."
  docker volume create LMS2
}

# Use the image's provided LLM for initial license setup-license
docker run --rm --detach --tty --volume LMS2:/usr/local/etc/IARSystems --name bx-license-setup ${PkgNameVersion}
${global:PackageDir} = docker exec bx-license-setup find /opt/iarsystems -type l
${global:ImagePackage} = ${PackageDir}.TrimStart("/opt/iarsystems").TrimStart("bx")
${global:ImageArch} = ${ImagePackage}.TrimEnd("fs")
docker exec bx-license-setup /opt/iarsystems/bx${ImagePackage}/common/bin/lightlicensemanager setup -s ${lms2ip}
docker stop bx-license-setup

Write-Output "-- setup-license: LMS2 license setup completed."
