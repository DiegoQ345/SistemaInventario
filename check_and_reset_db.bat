@echo off
echo ========================================
echo Script de Verificacion y Reset de BD
echo ========================================
echo.
echo Este script te ayudara a solucionar problemas con la base de datos.
echo.
echo IMPORTANTE: Este proceso eliminara TODOS los datos de la base de datos.
echo Solo continua si estas seguro de que quieres resetear la BD.
echo.
pause

echo.
echo [1/4] Cerrando aplicacion...
taskkill /F /IM appSistemaInventario.exe 2>nul
if %ERRORLEVEL% EQU 0 (
    echo    - Aplicacion cerrada correctamente
) else (
    echo    - La aplicacion no estaba en ejecucion
)
timeout /t 2 /nobreak >nul

echo.
echo [2/4] Localizando base de datos...
set DB_PATH=%APPDATA%\SistemaInventario\Sistema de Inventario\inventory.db
echo    - Ruta: %DB_PATH%

if exist "%DB_PATH%" (
    echo    - Base de datos encontrada
    echo.
    echo [3/4] Eliminando base de datos antigua...
    del "%DB_PATH%" /F /Q
    if %ERRORLEVEL% EQU 0 (
        echo    - Base de datos eliminada exitosamente
    ) else (
        echo    - ERROR: No se pudo eliminar la base de datos
        echo    - Verifica que no haya procesos usando el archivo
        pause
        exit /b 1
    )
) else (
    echo    - No se encontro base de datos existente
    echo [3/4] Saltando eliminacion...
)

echo.
echo [4/4] Proceso completado
echo.
echo ========================================
echo SIGUIENTE PASO:
echo ========================================
echo 1. Ejecuta la aplicacion desde Qt Creator
echo 2. La base de datos se regenerara automaticamente
echo 3. Se aplicaran todas las migraciones necesarias
echo.
echo Las columnas necesarias seran creadas:
echo   - sales.payment_status (PAID/PENDING/PARTIAL)
echo   - sales.payment_type (CONTADO/CREDITO)
echo   - sales.item_count (cantidad total de productos)
echo   - sales.product_names (lista de nombres de productos)
echo   - customers.current_debt
echo.
echo ========================================
pause
