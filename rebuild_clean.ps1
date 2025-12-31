# Script para limpiar y reconstruir el proyecto
# Ejecutar desde Qt Creator o directamente en PowerShell

Write-Host "Limpiando directorio de build..." -ForegroundColor Yellow

$buildDir = "g:\Repositorios\SistemaInventario\build\Desktop_Qt_6_10_1_MinGW_64_bit-Debug"

if (Test-Path $buildDir) {
    # Eliminar archivos de build pero mantener CMakeCache
    Remove-Item "$buildDir\CMakeFiles" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$buildDir\*.ninja" -Force -ErrorAction SilentlyContinue
    Remove-Item "$buildDir\*.ninja.d" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$buildDir\appSistemaInventario_autogen" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$buildDir\*.exe" -Force -ErrorAction SilentlyContinue
    Remove-Item "$buildDir\*.dll" -Force -ErrorAction SilentlyContinue
    
    Write-Host "Build limpiado exitosamente" -ForegroundColor Green
} else {
    Write-Host "Directorio de build no encontrado" -ForegroundColor Red
}

Write-Host "`nAhora ejecuta 'Build -> Rebuild Project' en Qt Creator" -ForegroundColor Cyan
