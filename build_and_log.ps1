# Script para compilar y guardar log
$ErrorActionPreference = "Continue"
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Output "Iniciando compilacion..."
Set-Location "build\Desktop_Qt_6_10_1_MinGW_64_bit-Debug"

# Ejecutar cmake build y guardar output
$output = cmake --build . 2>&1 | Out-String
$exitCode = $LASTEXITCODE

# Guardar en archivo
$output | Out-File -FilePath "..\..\build_log.txt" -Encoding UTF8

# Mostrar resumen
Write-Output "Codigo de salida: $exitCode"
Write-Output "Log guardado en build_log.txt"

if ($exitCode -ne 0) {
    Write-Output "ERRORES ENCONTRADOS:"
    $output -split "`n" | Where-Object { $_ -match "error|Error|ERROR" } | Select-Object -First 20
}

exit $exitCode
