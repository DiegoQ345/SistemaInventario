# Script de compilaci贸n con captura de errores
$ErrorActionPreference = "Continue"

Write-Host "=== Iniciando compilaci贸n ===" -ForegroundColor Green

try {
    # Navegar al directorio de build
    Set-Location "build\Desktop_Qt_6_10_1_MinGW_64_bit-Debug"
    
    # Limpiar cache de compilaci贸n de archivos modificados
    Remove-Item -Path "CMakeFiles\appSistemaInventario.dir\src\services\PrintService.cpp.obj" -ErrorAction SilentlyContinue
    
    # Compilar
    cmake --build . --target appSistemaInventario 2>&1 | Tee-Object -FilePath "..\..\compile_output.txt"
    
    $exitCode = $LASTEXITCODE
    Write-Host "`n=== Compilaci贸n finalizada con c贸digo: $exitCode ===" -ForegroundColor $(if ($exitCode -eq 0) { "Green" } else { "Red" })
    
    # Mostrar 煤ltimas l铆neas del output
    Get-Content "..\..\compile_output.txt" | Select-Object -Last 30
    
    exit $exitCode
} catch {
    Write-Host "Error durante la compilaci贸n: $_" -ForegroundColor Red
    exit 1
}
