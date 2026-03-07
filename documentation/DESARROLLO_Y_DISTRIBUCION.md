# Sistema de Inventario - Guía de Desarrollo y Distribución

## 🚀 Compilación y Empaquetado

### Método Rápido (Recomendado)

Usa el script automático:

```powershell
# Para version Release (distribución)
.\package_release.ps1

# Para version Debug (desarrollo)
.\package_release.ps1 -BuildType Debug
```

El script automáticamente:
- ✅ Compila el proyecto
- ✅ Ejecuta windeployqt
- ✅ Copia todos los archivos críticos
- ✅ Genera el paquete listo para distribuir

### Método Manual

Si necesitas compilar manualmente:

1. **Compilar:**
```powershell
cd build\Desktop_Qt_6_10_1_MinGW_64_bit-Release
$env:PATH = "C:\Qt\Tools\CMake_64\bin;C:\Qt\Tools\Ninja;C:\Qt\Tools\mingw1310_64\bin;C:\Qt\6.10.1\mingw_64\bin;$env:PATH"
ninja
```

2. **Crear paquete:**
```powershell
# Crear directorio
New-Item -ItemType Directory -Path "..\SistemaInventario-v1.0-Release" -Force

# Copiar ejecutable
Copy-Item "appSistemaInventario.exe" "..\SistemaInventario-v1.0-Release\"

# Ejecutar windeployqt
cd ..\SistemaInventario-v1.0-Release
C:\Qt\6.10.1\mingw_64\bin\windeployqt6.exe --qmldir ..\..\qml appSistemaInventario.exe
```

3. **⚠️ IMPORTANTE: Copiar archivos críticos manualmente:**

```powershell
# SQLite driver
New-Item -ItemType Directory -Path "sqldrivers" -Force
Copy-Item "C:\Qt\6.10.1\mingw_64\plugins\sqldrivers\qsqlite.dll" "sqldrivers\"

# Qt.labs.settings
New-Item -ItemType Directory -Path "qml\Qt\labs\settings" -Force
Copy-Item "C:\Qt\6.10.1\mingw_64\qml\Qt\labs\settings\*" "qml\Qt\labs\settings\" -Recurse

# Qt6LabsSettings.dll
Copy-Item "C:\Qt\6.10.1\mingw_64\bin\Qt6LabsSettings.dll" .
```

## ⚠️ Problemas Comunes al Hacer Cambios

### 1. "La aplicación no inicia después de recompilar"

**Causa:** Los archivos críticos no están en el paquete.

**Solución:** 
- Usa el script `package_release.ps1` en lugar de copiar manualmente
- Si compilas manualmente, verifica que estén estos archivos:
  - `sqldrivers\qsqlite.dll`
  - `Qt6LabsSettings.dll`
  - `qml\Qt\labs\settings\qmlsettingsplugin.dll`

### 2. "Error: módulo no está instalado"

**Causa:** Agregaste un nuevo `import` en QML que requiere un módulo adicional.

**Solución:**
1. Identifica el módulo faltante en el error
2. Busca el módulo en `C:\Qt\6.10.1\mingw_64\qml\`
3. Cópialo manualmente o agrégalo al script

### 3. "Crash inmediato al ejecutar"

**Causa:** Mezclaste DLLs de Debug y Release.

**Solución:**
- Elimina completamente el directorio de paquete
- Vuelve a ejecutar el script con el tipo correcto (`-BuildType Release` o `-BuildType Debug`)

### 4. "Cambios en código no se reflejan"

**Causa:** Estás ejecutando el paquete anterior.

**Solución:**
```powershell
# Recompilar y empaquetar
.\package_release.ps1
```

## 📋 Checklist Antes de Distribuir

Antes de comprimir y distribuir, verifica:

- [ ] Compilaste en modo **Release** (no Debug)
- [ ] El ejecutable es ~10 MB (no 80 MB)
- [ ] La aplicación inicia correctamente
- [ ] Puedes crear/editar productos
- [ ] Puedes realizar ventas
- [ ] La importación Excel funciona
- [ ] Los reportes se generan
- [ ] Existe `sqldrivers\qsqlite.dll`
- [ ] Existe `Qt6LabsSettings.dll`
- [ ] Existe `qml\Qt\labs\settings\qmlsettingsplugin.dll`

## 🔧 Modificaciones Frecuentes

### Cambiar versión de la aplicación

Edita `main.cpp`:
```cpp
app.setApplicationVersion("1.1.0");  // Cambiar aquí
```

### Agregar nuevas páginas QML

1. Crea el archivo en `qml/pages/`
2. Agrégalo a `CMakeLists.txt` en la sección `QML_FILES`
3. Recompila con el script

### Agregar nuevas dependencias Qt

Si necesitas un nuevo módulo Qt (ej: Qt6Network):

1. Agrega en `CMakeLists.txt`:
```cmake
find_package(Qt6 REQUIRED COMPONENTS 
    ...
    Network  # Nuevo módulo
)

target_link_libraries(appSistemaInventario
    PRIVATE 
        ...
        Qt6::Network  # Enlazar
)
```

2. Recompila completamente:
```powershell
Remove-Item build\Desktop_Qt_6_10_1_MinGW_64_bit-Release -Recurse -Force
.\package_release.ps1
```

## 📦 Crear Instalador (Opcional)

Para crear un instalador profesional, considera usar:

- **Inno Setup**: https://jrsoftware.org/isinfo.php
- **NSIS**: https://nsis.sourceforge.io/
- **WiX Toolset**: https://wixtoolset.org/

Ejemplo básico con Inno Setup:
1. Instala Inno Setup
2. Usa el paquete generado como fuente
3. Crea un script `.iss` que copie todos los archivos

## 🐛 Debug

Para ejecutar con logs de debug:

```powershell
cd build\SistemaInventario-v1.0-Release
$env:QT_DEBUG_PLUGINS=1
$env:QT_LOGGING_RULES="*.debug=true"
.\appSistemaInventario.exe
```

## 📝 Notas Importantes

1. **Nunca edites archivos en el directorio `build`** - se borrarán al recompilar
2. **Usa siempre el script de empaquetado** - garantiza consistencia
3. **Prueba el paquete en otra máquina** - verifica que no depende de tu instalación de Qt
4. **Guarda backups** - antes de cambios grandes, haz commit en Git

## 🆘 Soporte

Si encuentras problemas:
1. Verifica el checklist de arriba
2. Revisa los logs de compilación
3. Ejecuta con debug habilitado
4. Compara con un paquete que funcionaba anteriormente
