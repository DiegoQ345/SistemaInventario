@echo off
echo Cerrando aplicacion...
taskkill /F /IM appSistemaInventario.exe 2>nul
timeout /t 2 /nobreak >nul

echo Eliminando base de datos...
del "%APPDATA%\SistemaInventario\Sistema de Inventario\inventory.db" /F /Q

echo.
echo Base de datos eliminada correctamente.
echo Ahora ejecuta la aplicacion desde Qt Creator para regenerarla.
pause
