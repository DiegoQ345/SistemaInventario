# Estructura del Proyecto - Qt Creator

Este archivo ayuda a Qt Creator a reconocer la estructura del proyecto.

## Estado Actual

### ✅ Archivos compilándose:
- `main.cpp` - Punto de entrada
- `Main.qml` - Interfaz principal

### 📁 Archivos visibles en el proyecto (no compilados aún):
- `qml/pages/DashboardPage.qml`
- `qml/pages/ProductsPage.qml`
- Todos los archivos C++ en `src/`

### 📝 Para compilar el backend completo:
Editar `CMakeLists.txt` y descomentar:
```cmake
# ${SOURCE_FILES}
# ${HEADER_FILES}
```

## Archivos del proyecto

Todos los archivos están declarados en CMakeLists.txt para que Qt Creator los muestre en el árbol de archivos.
