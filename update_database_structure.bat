@echo off
echo ========================================
echo Actualizar Estructura de Base de Datos
echo ========================================
echo.
echo Este script actualizara la estructura de la base de datos
echo SIN ELIMINAR LOS DATOS EXISTENTES.
echo.
echo Se agregaran las columnas faltantes:
echo   - sales.payment_status
echo   - sales.payment_type
echo   - sales.item_count
echo   - sales.product_names
echo   - customers.current_debt
echo.
echo IMPORTANTE: Este proceso es seguro, no perdera sus datos.
echo.
pause

echo.
echo [1/3] Cerrando aplicacion...
taskkill /F /IM appSistemaInventario.exe 2>nul
if %ERRORLEVEL% EQU 0 (
    echo    - Aplicacion cerrada correctamente
) else (
    echo    - La aplicacion no estaba en ejecucion
)
timeout /t 2 /nobreak >nul

echo.
echo [2/3] Verificando base de datos...
set DB_PATH=%APPDATA%\SistemaInventario\Sistema de Inventario\inventory.db

if exist "%DB_PATH%" (
    echo    - Base de datos encontrada: %DB_PATH%
    
    echo.
    echo [3/3] Instrucciones:
    echo    1. Abre la aplicacion desde Qt Creator
    echo    2. Las migraciones pendientes se aplicaran automaticamente
    echo    3. Tus datos existentes se mantendran intactos
    echo    4. Solo se agregaran las columnas faltantes
    echo.
    echo NOTA: Si la base de datos esta en version antigua, las migraciones
    echo       7, 8 y 9 se ejecutaran automaticamente al iniciar la app.
    echo.
    echo ========================================
    echo La estructura se actualizara al ejecutar la app
    echo ========================================
) else (
    echo    - No se encontro base de datos existente
    echo    - Se creara una nueva base de datos al ejecutar la app
    echo.
)

echo.
pause
