# PowerShell

<# Copyright (c) 2022 IAR Systems AB
 #
 # aliases-set.ps1 - Set aliases for IAR Build Tools containers
 # 
 # See LICENSE for detailed license information
 #>

param(
  [parameter(Mandatory=$true)]
  # The container ID
  [String]${global:ContainerID}
)

#Find the Build Tools
${global:PackageDir} = docker exec ${ContainerID} find /opt/iarsystems -type l
${global:ImagePackage} = ${PackageDir}.TrimStart("/opt/iarsystems").TrimStart("bx")
${global:ImageArch} = ${ImagePackage}.TrimEnd("fs")

# <arch> execs
Function global:bx_iasm { docker exec ${ContainerID} ${PackageDir}/${ImageArch}/bin/iasm${ImageArch} ${args} }
Set-Alias -Scope Global -Name iasm${ImageArch} -Value bx_iasm
Function global:bx_icc { docker exec ${ContainerID} ${PackageDir}/${ImageArch}/bin/icc${ImageArch} ${args} }
Set-Alias -Scope Global -Name icc${ImageArch} -Value bx_icc
Function global:bx_ielfdump { docker exec ${ContainerID} ${PackageDir}/${ImageArch}/bin/ielfdump${ImageArch} ${args} }
Set-Alias -Scope Global -Name ielfdump${ImageArch} -Value bx_ielfdump
Function global:bx_ilink { docker exec ${ContainerID} ${PackageDir}/${ImageArch}/bin/ilink${ImageArch} ${args} }
Set-Alias -Scope Global -Name ilink${ImageArch} -Value bx_ilink
# non-<arch> execs
Function global:bx_iarbuild { docker exec ${ContainerID} ${PackageDir}/common/bin/iarbuild ${args} }
Set-Alias -Scope Global -Name iarbuild -Value bx_iarbuild
Function global:bx_iarchive { docker exec ${ContainerID} ${PackageDir}/${ImageArch}/bin/iarchive ${args} }
Set-Alias -Scope Global -Name iarchive -Value bx_iarbuild
Function global:bx_ichecks { docker exec ${ContainerID} ${PackageDir}/${ImageArch}/bin/ichecks ${args} }
Set-Alias -Scope Global -Name ichecks -Value bx_ichecks
Function global:bx_icstat { docker exec ${ContainerID} ${PackageDir}/${ImageArch}/bin/icstat ${args} }
Set-Alias -Scope Global -Name icstat -Value bx_icstat
Function global:bx_ielftool { docker exec ${ContainerID} ${PackageDir}/${ImageArch}/bin/ielftool ${args} }
Set-Alias -Scope Global -Name ielftool -Value bx_ielftool
Function global:bx_iexe2obj { docker exec ${ContainerID} ${PackageDir}/${ImageArch}/bin/iexe2obj ${args} }
Set-Alias -Scope Global -Name iexe2obj -Value bx_iexe2obj
Function global:bx_isymexport { docker exec ${ContainerID} ${PackageDir}/${ImageArch}/bin/isymexport ${args} }
Set-Alias -Scope Global -Name isymexport -Value bx_isymexport
Function global:bx_iobjmanip { docker exec ${ContainerID} ${PackageDir}/${ImageArch}/bin/iobjmanip ${args} }
Set-Alias -Scope Global -Name iobjmanip -Value bx_iobjmanip
Function global:bx_ireport { docker exec ${ContainerID} ${PackageDir}/${ImageArch}/bin/ireport ${args} }
Set-Alias -Scope Global -Name ireport -Value bx_ireport

Write-Output "-- The following aliases for IAR Build Tools were set:"
get-alias -Name i*${ImageArch},iarbuild,iarchive,ichecks,icstat,ielftool,iexe2obj,isymexport,iobjmanip,ireport `
          | Select-String -Pattern i*
Write-Output "-- Now it is possible to execute the build tools seamlessly from the PowerShell."
