# Cómo Instalar QXlsx para Compilar el Backend Completo

QXlsx es necesario para la funcionalidad de **importación desde Excel**.

## Opción 1: Usar vcpkg (RECOMENDADO) ⭐

vcpkg es el gestor de paquetes de Microsoft para C++.

### Paso 1: Instalar vcpkg

```powershell
# En cualquier ubicación (ejemplo: C:\dev\)
cd C:\dev
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
```

### Paso 2: Instalar QXlsx

```powershell
# Desde la carpeta de vcpkg
.\vcpkg install qxlsx:x64-windows
```

### Paso 3: Integrar con CMake

Edita tu **CMakeLists.txt** y agrega:

```cmake
# Al inicio del archivo, después de project()
set(CMAKE_TOOLCHAIN_FILE "C:/dev/vcpkg/scripts/buildsystems/vcpkg.cmake")

# Después de find_package(Qt6...)
find_package(QXlsx REQUIRED)

# En target_link_libraries
target_link_libraries(appSistemaInventario
    PRIVATE 
        Qt6::Core
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Sql
        Qt6::PrintSupport
        QXlsx::QXlsx  # ← AGREGAR ESTO
)
```

---

## Opción 2: Añadir como Submódulo Git

### Paso 1: Añadir submódulo

```powershell
cd G:\Repositorios\SistemaInventario
git submodule add https://github.com/QtExcel/QXlsx.git external/QXlsx
```

### Paso 2: Modificar CMakeLists.txt

```cmake
# Agregar después de find_package(Qt6...)
add_subdirectory(external/QXlsx/QXlsx)

# En target_link_libraries
target_link_libraries(appSistemaInventario
    PRIVATE 
        Qt6::Core
        # ... otros ...
        QXlsx::QXlsx
)
```

---

## Opción 3: Descarga Manual (No recomendada)

### Paso 1: Descargar
- Ve a: https://github.com/QtExcel/QXlsx/releases
- Descarga la última versión
- Extrae en `G:\Repositorios\SistemaInventario\external\QXlsx`

### Paso 2: Igual que Opción 2

---

## ✅ Verificar Instalación

Después de instalar QXlsx:

1. **Edita CMakeLists.txt** y descomenta:
   ```cmake
   # ${SOURCE_FILES}
   # ${HEADER_FILES}
   ```

2. **Descomenta QML_ELEMENT** en los headers:
   - `src/viewmodels/DashboardViewModel.h`
   - `src/viewmodels/ProductListModel.h`
   - `src/utils/BarcodeScannerHandler.h`

3. **Reconfigura el proyecto en Qt Creator**:
   - Build → Run CMake
   - O cierra y reabre el proyecto

4. **Compila**: Ctrl+B

---

## 🎯 Recomendación

Usa **Opción 1 (vcpkg)** porque:
- ✅ Maneja dependencias automáticamente
- ✅ Compatible con Qt Creator
- ✅ Fácil de actualizar
- ✅ Estándar de la industria

---

## Notas Importantes

⚠️ **Por ahora NO es necesario** instalar QXlsx. El proyecto compila correctamente sin él usando datos de prueba.

Solo instala QXlsx cuando:
1. Quieras compilar el backend completo
2. Necesites la funcionalidad real de importación Excel
3. Estés listo para integrar la base de datos
