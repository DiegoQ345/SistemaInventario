# 🗄️ Base de Datos - Sistema de Inventario

## Ubicación de la Base de Datos

La base de datos **se crea automáticamente** cuando ejecutas la aplicación por primera vez.

### 📍 Ruta en tu sistema:
```
C:\Users\Adm\AppData\Local\SistemaInventario\inventory.db
```

### Tipo de Base de Datos
**SQLite** - Un archivo único que contiene toda la información:
- ✅ No requiere instalación de servidor
- ✅ Portable (puedes copiar el archivo)
- ✅ Ideal para aplicaciones de escritorio
- ✅ Soporta hasta millones de registros

---

## 🔧 Cómo se Crea Automáticamente

### 1. En el código actual (main.cpp):

```cpp
// Cuando el backend esté compilado, se ejecutará esto:
DatabaseManager& db = DatabaseManager::instance();

// Se crea automáticamente en:
// C:\Users\[TuUsuario]\AppData\Local\SistemaInventario\inventory.db
if (!db.initialize()) {
    qCritical() << "Error inicializando base de datos";
    return -1;
}
```

### 2. Qué hace `initialize()`:

1. **Crea la carpeta** si no existe:
   - `C:\Users\Adm\AppData\Local\SistemaInventario\`

2. **Crea el archivo** `inventory.db` si no existe

3. **Ejecuta migraciones** (crea tablas automáticamente):
   - `categories` - Categorías de productos
   - `products` - Productos
   - `customers` - Clientes
   - `sales` - Ventas
   - `sale_items` - Items de venta
   - `stock_movements` - Movimientos de stock (Kardex)
   - `payment_methods` - Métodos de pago
   - `movement_types` - Tipos de movimiento
   - `users` - Usuarios del sistema
   - `import_templates` - Plantillas de importación Excel
   - `schema_version` - Control de versiones

4. **Habilita integridad referencial** (FOREIGN KEYS)

---

## 📊 Esquema de la Base de Datos

### Tabla: products
```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    sku TEXT UNIQUE,                  -- Código SKU
    barcode TEXT UNIQUE,              -- Código de barras
    category_id INTEGER,
    current_stock REAL DEFAULT 0,
    minimum_stock REAL DEFAULT 0,     -- Para alertas
    purchase_price REAL DEFAULT 0,
    sale_price REAL DEFAULT 0,
    description TEXT,
    image_path TEXT,
    active INTEGER DEFAULT 1,         -- Soft delete
    created_at TEXT,
    updated_at TEXT,
    FOREIGN KEY (category_id) REFERENCES categories(id)
);
```

### Tabla: sales
```sql
CREATE TABLE sales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_number TEXT UNIQUE,
    customer_id INTEGER,
    subtotal REAL NOT NULL,
    tax REAL DEFAULT 0,
    discount REAL DEFAULT 0,
    total REAL NOT NULL,
    payment_method_id INTEGER,
    status TEXT DEFAULT 'COMPLETED',  -- COMPLETED, CANCELLED, PENDING
    created_at TEXT,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id)
);
```

### Tabla: stock_movements (Kardex)
```sql
CREATE TABLE stock_movements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL,
    movement_type_id INTEGER NOT NULL,
    quantity REAL NOT NULL,
    previous_stock REAL NOT NULL,
    new_stock REAL NOT NULL,
    unit_price REAL,
    reference TEXT,                   -- Referencia (ej: venta #123)
    created_at TEXT,
    FOREIGN KEY (product_id) REFERENCES products(id)
);
```

Ver esquema completo en [ARQUITECTURA.md](ARQUITECTURA.md)

---

## 🚀 Estado Actual del Proyecto

### ⏳ Base de Datos NO Creada Aún

**Por qué:**
- El backend C++ (DatabaseManager) **no está compilado**
- Estás usando datos de prueba temporales en QML

**Cuándo se creará:**
1. Cuando compiles el backend completo
2. La primera vez que ejecutes la aplicación compilada

---

## ✅ Cómo Activar la Base de Datos Real

### Paso 1: Instalar QXlsx (opcional)
Sigue [INSTALL_QXLSX.md](INSTALL_QXLSX.md) si quieres importación Excel.

O comenta temporalmente las referencias a QXlsx en:
- `src/services/ExcelImportService.cpp`
- `src/services/ExcelImportService.h`

### Paso 2: Compilar el Backend

Edita [CMakeLists.txt](CMakeLists.txt):

```cmake
# Descomentar líneas 69-70:
qt_add_executable(appSistemaInventario
    main.cpp
    ${SOURCE_FILES}    # ← DESCOMENTAR
    ${HEADER_FILES}    # ← DESCOMENTAR
)
```

### Paso 3: Activar Inicialización en main.cpp

Edita [main.cpp](main.cpp) y agrega:

```cpp
#include "src/database/DatabaseManager.h"
#include "src/viewmodels/DashboardViewModel.h"
#include "src/viewmodels/ProductListModel.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    // ← AGREGAR ESTO:
    qDebug() << "=== Inicializando Base de Datos ===";
    DatabaseManager& db = DatabaseManager::instance();
    if (!db.initialize()) {
        qCritical() << "Error:" << db.lastError();
        return -1;
    }
    qDebug() << "✓ Base de datos lista";

    // Registrar tipos QML
    qmlRegisterType<DashboardViewModel>("SistemaInventario", 1, 0, "DashboardViewModel");
    qmlRegisterType<ProductListModel>("SistemaInventario", 1, 0, "ProductListModel");
    
    // ... resto del código
}
```

### Paso 4: Descomentar QML_ELEMENT

En los 3 headers, descomentar:
- `src/viewmodels/DashboardViewModel.h` línea 16
- `src/viewmodels/ProductListModel.h` línea 18  
- `src/utils/BarcodeScannerHandler.h` línea 20

### Paso 5: Reconfigurar y Compilar

1. Qt Creator → Build → Run CMake
2. Ctrl+B para compilar
3. Ejecutar (Ctrl+R)

---

## 📂 Herramientas para Ver la Base de Datos

### Opción 1: DB Browser for SQLite (RECOMENDADO)
- **Descarga**: https://sqlitebrowser.org/
- **Gratis** y Open Source
- Interfaz gráfica para SQLite
- Ver tablas, ejecutar queries, exportar datos

### Opción 2: DBeaver
- **Descarga**: https://dbeaver.io/
- Soporta múltiples bases de datos
- Más completo pero más pesado

### Opción 3: VS Code Extension
- Extensión: **SQLite Viewer**
- Integrado en VS Code / Cursor

### Cómo abrir:
1. Ejecuta la app una vez (se crea la BD)
2. Abre con cualquier herramienta:
   ```
   C:\Users\Adm\AppData\Local\SistemaInventario\inventory.db
   ```

---

## 🔍 Verificar que Existe la Base de Datos

```powershell
# Verificar si existe
Test-Path "$env:LOCALAPPDATA\SistemaInventario\inventory.db"

# Ver contenido de la carpeta
Get-ChildItem "$env:LOCALAPPDATA\SistemaInventario"

# Ver tamaño del archivo
(Get-Item "$env:LOCALAPPDATA\SistemaInventario\inventory.db").Length / 1KB
```

---

## 🎯 Respuesta Rápida

### La base de datos:
- **Tipo**: SQLite (archivo único)
- **Ubicación**: `C:\Users\Adm\AppData\Local\SistemaInventario\inventory.db`
- **Estado**: NO existe aún (backend no compilado)
- **Se crea**: Automáticamente al ejecutar la app con backend compilado
- **Tablas**: 11 tablas creadas automáticamente por migraciones
- **Datos**: Inicialmente vacía, lista para usar

### Para crear la BD ahora:
1. Compila el backend C++ (descomentar en CMakeLists.txt)
2. Ejecuta la aplicación (Ctrl+R)
3. ✅ La BD se crea automáticamente en la primera ejecución

No necesitas SQL ni scripts manuales - todo es automático! 🚀
