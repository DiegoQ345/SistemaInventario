# Script de verificación del proyecto
Write-Host "=== Verificando configuración del proyecto ===" -ForegroundColor Cyan

# Verificar archivos esenciales
Write-Host "`nVerificando archivos esenciales..." -ForegroundColor Yellow
$files = @(
    "CMakeLists.txt",
    "main.cpp",
    "Main.qml",
    "qml\pages\DashboardPage.qml",
    "qml\pages\ProductsPage.qml"
)

$allFilesExist = $true
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (NO ENCONTRADO)" -ForegroundColor Red
        $allFilesExist = $false
    }
}

# Verificar imports incorrectos en QML
Write-Host "`nVerificando imports QML..." -ForegroundColor Yellow
$qmlFiles = Get-ChildItem -Path "qml\pages" -Filter "*.qml" -Recurse

foreach ($qmlFile in $qmlFiles) {
    $content = Get-Content $qmlFile.FullName -Raw
    
    # Verificar que NO importe SistemaInventario (porque los viewmodels no están compilados)
    if ($content -match "import SistemaInventario") {
        Write-Host "  ✗ $($qmlFile.Name): Importa 'SistemaInventario' sin estar compilado" -ForegroundColor Red
        $allFilesExist = $false
    } else {
        Write-Host "  ✓ $($qmlFile.Name): Sin imports problemáticos" -ForegroundColor Green
    }
    
    # Verificar que importe Material si lo usa
    if (($content -match "Material\.") -and ($content -notmatch "import QtQuick\.Controls\.Material")) {
        Write-Host "  ✗ $($qmlFile.Name): Usa Material sin importarlo" -ForegroundColor Red
        $allFilesExist = $false
    }
}

Write-Host "`n=== Resultado ===" -ForegroundColor Cyan
if ($allFilesExist) {
    Write-Host "✓ Todo está correcto. El proyecto debería compilar sin errores." -ForegroundColor Green
    Write-Host "`nPuedes compilar con: Ctrl+B en Qt Creator" -ForegroundColor Yellow
} else {
    Write-Host "✗ Hay problemas que deben corregirse antes de compilar." -ForegroundColor Red
}
