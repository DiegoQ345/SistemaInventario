# =============================================================================
# package.ps1 — Empaquetado dinámico de SistemaInventario
# Detecta automáticamente la versión de Qt, el directorio de build y genera
# el distribuible listo para distribuir.
# Uso: .\package.ps1 [-BuildType Debug|Release] [-SkipBuild]
# =============================================================================
param(
    [string]$BuildType = "Release",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── 1. Detectar instalación de Qt (busca en G:\qt y C:\Qt) ─────────────────
function Find-QtInstall {
    $searchRoots = @("G:\qt", "C:\Qt", "D:\Qt")
    $candidates = @()

    foreach ($root in $searchRoots) {
        if (-not (Test-Path $root)) { continue }
        Get-ChildItem $root -Directory | Where-Object { $_.Name -match '^\d+\.\d+' } | ForEach-Object {
            $mingwDir = Join-Path $_.FullName "mingw_64"
            $windeployqt = Join-Path $mingwDir "bin\windeployqt6.exe"
            if (Test-Path $windeployqt) {
                $candidates += [PSCustomObject]@{
                    Version    = $_.Name
                    QtPath     = $mingwDir
                    ToolsPath  = Split-Path -Parent $_.FullName | Join-Path -ChildPath "Tools"
                }
            }
        }
    }

    if ($candidates.Count -eq 0) {
        throw "No se encontró ninguna instalación de Qt con mingw_64. Verifica que Qt esté instalado."
    }

    # Preferir la versión más reciente
    return ($candidates | Sort-Object Version -Descending)[0]
}

# ── 2. Detectar directorio de build más reciente ────────────────────────────
function Find-BuildDir {
    param([string]$BuildType)
    $buildRoot = Join-Path $ProjectRoot "build"
    if (-not (Test-Path $buildRoot)) {
        throw "No existe el directorio build\. Compila el proyecto primero desde Qt Creator."
    }

    # Buscar carpetas que coincidan con el patrón Desktop_Qt_*_MinGW_*-$BuildType
    $pattern = "*MinGW*-$BuildType"
    $dirs = Get-ChildItem $buildRoot -Directory | Where-Object { $_.Name -like $pattern }

    if ($dirs.Count -eq 0) {
        # Intentar con cualquier build disponible
        $dirs = Get-ChildItem $buildRoot -Directory | Where-Object { $_.Name -like "*MinGW*" }
    }

    if ($dirs.Count -eq 0) {
        throw "No se encontró directorio de build de tipo '$BuildType'. Compila primero desde Qt Creator."
    }

    # Preferir el más reciente por fecha de modificación
    $chosen = ($dirs | Sort-Object LastWriteTime -Descending)[0]
    return $chosen.FullName
}

# ── 3. Detectar ninja.exe ───────────────────────────────────────────────────
function Find-Ninja {
    param([string]$ToolsRoot)
    $candidates = @(
        (Join-Path $ToolsRoot "Ninja\ninja.exe"),
        "G:\qt\Tools\Ninja\ninja.exe",
        "C:\Qt\Tools\Ninja\ninja.exe"
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) { return $p }
    }
    # Buscar en PATH
    $found = Get-Command ninja.exe -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
    throw "No se encontró ninja.exe. Instala Qt Creator o agrega ninja al PATH."
}

# ── 4. Resolución dinámica ──────────────────────────────────────────────────
Write-Host "`n=== SistemaInventario — Empaquetador Dinámico ===" -ForegroundColor Cyan

$qt = Find-QtInstall
Write-Host "Qt detectado  : $($qt.Version) en $($qt.QtPath)" -ForegroundColor Green

$BuildDir = Find-BuildDir -BuildType $BuildType
Write-Host "Build dir     : $BuildDir" -ForegroundColor Green

$Ninja = Find-Ninja -ToolsRoot $qt.ToolsPath
Write-Host "Ninja         : $Ninja" -ForegroundColor Green

$ExeName = "appSistemaInventario.exe"
$ExePath  = Join-Path $BuildDir $ExeName

# Nombre del paquete incluye versión Qt y tipo de build
$PackageDir = Join-Path $ProjectRoot "dist\SistemaInventario-Qt$($qt.Version)-$BuildType"
Write-Host "Distribuible  : $PackageDir`n" -ForegroundColor Green

# ── 5. Compilar ─────────────────────────────────────────────────────────────
if (-not $SkipBuild) {
    Write-Host "► Compilando..." -ForegroundColor Yellow
    Push-Location $BuildDir
    & $Ninja
    $exitCode = $LASTEXITCODE
    Pop-Location

    if ($exitCode -ne 0) {
        throw "La compilación falló (exit code $exitCode). Revisa los errores arriba."
    }
    Write-Host "  Compilación exitosa.`n" -ForegroundColor Green
} else {
    Write-Host "► Compilación omitida (-SkipBuild).`n" -ForegroundColor DarkGray
}

if (-not (Test-Path $ExePath)) {
    throw "No se encontró el ejecutable: $ExePath"
}

# ── 6. Preparar directorio del paquete ──────────────────────────────────────
Write-Host "► Preparando distribuible..." -ForegroundColor Yellow
if (Test-Path $PackageDir) {
    # Quitar atributo ReadOnly en todos los archivos antes de borrar
    Get-ChildItem $PackageDir -Recurse -File | ForEach-Object {
        $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
    }
    Remove-Item $PackageDir -Recurse -Force
}
New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null

Copy-Item $ExePath $PackageDir

# ── 7. windeployqt6 ─────────────────────────────────────────────────────────
Write-Host "► Ejecutando windeployqt6..." -ForegroundColor Yellow
Push-Location $PackageDir
& "$($qt.QtPath)\bin\windeployqt6.exe" --qmldir "$ProjectRoot\qml" $ExeName
Pop-Location

# ── 8. Copiar dependencias extras necesarias en runtime ─────────────────────
Write-Host "► Copiando dependencias extras..." -ForegroundColor Yellow

# SQLite driver
$sqliteSrc = "$($qt.QtPath)\plugins\sqldrivers\qsqlite.dll"
if (Test-Path $sqliteSrc) {
    New-Item -ItemType Directory -Path "$PackageDir\sqldrivers" -Force | Out-Null
    Copy-Item $sqliteSrc "$PackageDir\sqldrivers\" -Force
    Write-Host "  qsqlite.dll copiado."
}

# Qt.labs.settings
$settingsSrc = "$($qt.QtPath)\qml\Qt\labs\settings"
if (Test-Path $settingsSrc) {
    New-Item -ItemType Directory -Path "$PackageDir\qml\Qt\labs\settings" -Force | Out-Null
    Copy-Item "$settingsSrc\*" "$PackageDir\qml\Qt\labs\settings\" -Recurse -Force
    Write-Host "  Qt.labs.settings copiado."
}
$settingsDll = "$($qt.QtPath)\bin\Qt6LabsSettings.dll"
if (Test-Path $settingsDll) {
    Copy-Item $settingsDll $PackageDir -Force
    Write-Host "  Qt6LabsSettings.dll copiado."
}

# QtQuick.Effects (blur/shadow)
$effectsSrc = "$($qt.QtPath)\qml\QtQuick\Effects"
if (Test-Path $effectsSrc) {
    New-Item -ItemType Directory -Path "$PackageDir\qml\QtQuick\Effects" -Force | Out-Null
    Copy-Item "$effectsSrc\*" "$PackageDir\qml\QtQuick\Effects\" -Recurse -Force
    Write-Host "  QtQuick.Effects copiado."
}

# ── 9. Comprimir a ZIP ──────────────────────────────────────────────────────
Write-Host "`n► Comprimiendo distribuible..." -ForegroundColor Yellow
$ZipPath = "$PackageDir.zip"
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
Compress-Archive -Path "$PackageDir\*" -DestinationPath $ZipPath -CompressionLevel Optimal
Write-Host "  ZIP generado: $ZipPath" -ForegroundColor Green

# ── 10. Resumen ──────────────────────────────────────────────────────────────
$sizeDir = (Get-ChildItem $PackageDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
$sizeZip = (Get-Item $ZipPath).Length / 1MB
Write-Host "`n=== LISTO ===" -ForegroundColor Cyan
Write-Host "Carpeta distribuible : $PackageDir"
Write-Host "Tamaño carpeta       : $([math]::Round($sizeDir, 1)) MB"
Write-Host "ZIP generado         : $ZipPath"
Write-Host "Tamaño ZIP           : $([math]::Round($sizeZip, 1)) MB"
Write-Host ""
Write-Host "Para ejecutar: cd '$PackageDir' ; .\$ExeName" -ForegroundColor Yellow
