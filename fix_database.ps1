# Script para agregar manualmente las columnas de facturación a la tabla sales

$dbPath = "$env:APPDATA\SistemaInventario\Sistema de Inventario\inventory.db"

Write-Host "Intentando agregar columnas a la tabla sales..." -ForegroundColor Yellow
Write-Host "Ruta DB: $dbPath"

# Verificar que el archivo existe
if (-not (Test-Path $dbPath)) {
    Write-Host "ERROR: No se encontró la base de datos en: $dbPath" -ForegroundColor Red
    exit 1
}

# Cargar ensamblado de SQLite
Add-Type -Path "C:\Qt\6.10.2\mingw_64\plugins\sqldrivers\qsqlite.dll" -ErrorAction SilentlyContinue

# Usar .NET System.Data.SQLite si está disponible
try {
    Add-Type -AssemblyName System.Data.SQLite -ErrorAction Stop
    
    $connectionString = "Data Source=$dbPath;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
    $connection.Open()
    
    Write-Host "`nAgregando columnas..." -ForegroundColor Cyan
    
    # Agregar customer_name
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = "ALTER TABLE sales ADD COLUMN customer_name TEXT"
    try {
        $cmd.ExecuteNonQuery() | Out-Null
        Write-Host "✓ Columna customer_name agregada" -ForegroundColor Green
    } catch {
        Write-Host "! customer_name: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Agregar customer_ruc
    $cmd.CommandText = "ALTER TABLE sales ADD COLUMN customer_ruc TEXT"
    try {
        $cmd.ExecuteNonQuery() | Out-Null
        Write-Host "✓ Columna customer_ruc agregada" -ForegroundColor Green
    } catch {
        Write-Host "! customer_ruc: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Agregar customer_business_name
    $cmd.CommandText = "ALTER TABLE sales ADD COLUMN customer_business_name TEXT"
    try {
        $cmd.ExecuteNonQuery() | Out-Null
        Write-Host "✓ Columna customer_business_name agregada" -ForegroundColor Green
    } catch {
        Write-Host "! customer_business_name: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Agregar customer_address
    $cmd.CommandText = "ALTER TABLE sales ADD COLUMN customer_address TEXT"
    try {
        $cmd.ExecuteNonQuery() | Out-Null
        Write-Host "✓ Columna customer_address agregada" -ForegroundColor Green
    } catch {
        Write-Host "! customer_address: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    $connection.Close()
    Write-Host "`n✓ Proceso completado" -ForegroundColor Green
    
} catch {
    Write-Host "`nERROR: No se pudo conectar a la base de datos" -ForegroundColor Red
    Write-Host "Mensaje: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nAlternativa: Elimina la base de datos y déjala regenerar:" -ForegroundColor Yellow
    Write-Host "  Remove-Item '$dbPath'" -ForegroundColor Cyan
    exit 1
}
