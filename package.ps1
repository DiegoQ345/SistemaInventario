# Script de empaquetado automatico
param([string]$BuildType = "Release")

$QtPath = "C:\Qt\6.10.1\mingw_64"
$QtToolsPath = "C:\Qt\Tools"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildDir = "$ProjectRoot\build\Desktop_Qt_6_10_1_MinGW_64_bit-$BuildType"
$PackageDir = "$ProjectRoot\build\SistemaInventario-v1.0-$BuildType"

$env:PATH = "$QtToolsPath\CMake_64\bin;$QtToolsPath\Ninja;$QtToolsPath\mingw1310_64\bin;$QtPath\bin;$env:PATH"

Write-Host "Limpiando paquete anterior..."
if (Test-Path $PackageDir) {Remove-Item $PackageDir -Recurse -Force}

Write-Host "Compilando..."
Set-Location $BuildDir
& "C:\Qt\Tools\Ninja\ninja.exe"

Write-Host "Creando paquete..."
New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null
Copy-Item "$BuildDir\appSistemaInventario.exe" $PackageDir

Set-Location $PackageDir
& "$QtPath\bin\windeployqt6.exe" --qmldir "$ProjectRoot\qml" appSistemaInventario.exe

Write-Host "Copiando archivos criticos..."
New-Item -ItemType Directory -Path "sqldrivers" -Force | Out-Null
Copy-Item "$QtPath\plugins\sqldrivers\qsqlite.dll" "sqldrivers\" -Force

New-Item -ItemType Directory -Path "qml\Qt\labs\settings" -Force | Out-Null
Copy-Item "$QtPath\qml\Qt\labs\settings\*" "qml\Qt\labs\settings\" -Recurse -Force

Copy-Item "$QtPath\bin\Qt6LabsSettings.dll" . -Force

# QtQuick.Effects para blur/desenfoque
New-Item -ItemType Directory -Path "qml\QtQuick\Effects" -Force | Out-Null
Copy-Item "$QtPath\qml\QtQuick\Effects\*" "qml\QtQuick\Effects\" -Recurse -Force

Write-Host ""
Write-Host "PAQUETE GENERADO EN: $PackageDir"
Set-Location $ProjectRoot
