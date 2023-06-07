# Powershell

<# Copyright (c) 2022 IAR Systems AB
 #
 # build.ps1 - Build a Docker image containing the IAR Build Tools
 # 
 # See LICENSE for detailed license information
 #>

param(
  [parameter(Mandatory=$true)]
  # /path/to/bx<arch>-<version>.deb installer package.
  [String]${package}
)

${CheckPath} = Test-Path -Path ${package} -PathType Leaf
if (${CheckPath} -eq $False) {
  Write-Output "ERROR: file -${package}- not found."
  Exit 1
}

${PkgFullPath} = Get-ChildItem -Path ${package}
${PkgPath} = Split-Path ${PkgFullPath} -Parent
${PkgFile} = Split-Path ${PkgFullPath} -leaf
${PkgBase} = ${PkgFile}.TrimEnd(".deb")
${PkgName} = ${PkgBase}.Split("-")[0]
${PkgVersion} = ${PkgBase}.Split("-")[-1]

Switch (${PkgName}) {
  bxarm { ${BxArch} = "arm" }
  bxarmfs { ${BxArch} = "arm" }
  bxrh850 { ${BxArch} = "rh850" }
  bxrh850fs { ${BxArch} = "rh850" }
  bxriscv { ${BxArch} = "riscv" }
  bxbxriscvfs { ${BxArch} = "riscv" }
  bxrl78 { ${BxArch} = "rl78" }
  bxrx { ${BxArch} = "rx" }
  default { "ERROR: invalid package. (${PkgName})" }
}

# Copy the installer package to the Docker context
${ScriptPath} = Split-Path ${PSCommandPath} -Parent
Copy-Item ${PkgFullPath} ${ScriptPath}

Write-Output "-- Building the Docker image for ${PkgName}-${PkgVersion}..."
docker build --tag iarsystems/${PkgName}":"${PkgVersion} ${ScriptPath}

# Cleanup
Write-Output "Removing ${ScriptPath}/${PkgFile}..."
Remove-Item ${ScriptPath}/${PkgFile}
