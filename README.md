# Sistema de Inventario - Documentación Completa

## 📋 Descripción General

Sistema completo de gestión de inventario y logística para Windows, desarrollado con Qt 6 y C++. Aplicación de escritorio con arquitectura MVVM, diseñada para ser intuitiva, moderna y lista para producción.

## 🏗️ Arquitectura del Sistema

### Estructura de Capas

```
┌─────────────────────────────────────┐
│         Interfaz QML (View)         │  ← Material Design, responsive
├─────────────────────────────────────┤
│      ViewModels (MVVM Pattern)      │  ← Expone datos a QML
├─────────────────────────────────────┤
│   Servicios de Negocio (Services)   │  ← Lógica de negocio
├─────────────────────────────────────┤
│    Repositorios (Data Access)       │  ← Acceso a datos
├─────────────────────────────────────┤
│      Base de Datos (SQLite)         │  ← Persistencia
└─────────────────────────────────────┘
```

### Patrón MVVM (Model-View-ViewModel)

**Ventajas de esta arquitectura:**
- ✅ Separación clara de responsabilidades
- ✅ Facilita testing unitario
- ✅ Código mantenible y escalable
- ✅ Interfaz desacoplada de la lógica

## 📁 Estructura de Directorios

```
SistemaInventario/
├── src/
│   ├── database/          # Gestión de base de datos
│   │   ├── DatabaseManager.h/cpp
│   │   └── Migraciones automáticas
│   ├── models/            # Modelos de dominio (POJOs)
│   │   ├── Product.h
│   │   ├── Sale.h
│   │   ├── Customer.h
│   │   └── StockMovement.h
│   ├── repositories/      # Acceso a datos (patrón Repository)
│   │   ├── ProductRepository.h/cpp
│   │   └── SaleRepository.h/cpp
│   ├── services/          # Lógica de negocio
│   │   ├── ProductService.h/cpp
│   │   ├── SalesService.h/cpp
│   │   ├── ExcelImportService.h/cpp  ← Importación Excel
│   │   └── PdfGeneratorService.h/cpp ← Generación de PDF
│   ├── viewmodels/        # ViewModels para MVVM
│   │   ├── DashboardViewModel.h/cpp
│   │   └── ProductListModel.h/cpp
│   └── utils/             # Utilidades
│       └── BarcodeScannerHandler.h/cpp
├── qml/                   # Interfaz de usuario
│   ├── pages/             # Páginas de la aplicación
│   │   ├── DashboardPage.qml
│   │   └── ProductsPage.qml
│   └── components/        # Componentes reutilizables
├── Main.qml               # Punto de entrada QML
├── main.cpp               # Punto de entrada C++
└── CMakeLists.txt         # Configuración de compilación
```

## 🗄️ Esquema de Base de Datos

### Tablas Principales

**products** (Productos)
```sql
- id: INTEGER PRIMARY KEY
- name: TEXT (nombre del producto)
- sku: TEXT UNIQUE (código SKU)
- barcode: TEXT UNIQUE (código de barras)
- category_id: INTEGER
- current_stock: REAL (stock actual)
- minimum_stock: REAL (stock mínimo)
- purchase_price: REAL
- sale_price: REAL
- description: TEXT
- active: BOOLEAN
```

**sales** (Ventas)
```sql
- id: INTEGER PRIMARY KEY
- invoice_number: TEXT UNIQUE
- customer_id: INTEGER
- subtotal: REAL
- tax: REAL
- discount: REAL
- total: REAL
- payment_method_id: INTEGER
- status: TEXT (COMPLETED, CANCELLED, PENDING)
- created_at: DATETIME
```

**stock_movements** (Kardex)
```sql
- id: INTEGER PRIMARY KEY
- product_id: INTEGER
- movement_type_id: INTEGER
- quantity: REAL
- previous_stock: REAL
- new_stock: REAL
- unit_price: REAL
- reference: TEXT
- created_at: DATETIME
```

### Migraciones Automáticas

El sistema implementa un sistema de migraciones automático:
- Al iniciar, verifica la versión del esquema
- Aplica migraciones pendientes automáticamente
- Garantiza integridad referencial (FOREIGN KEYS)
- Índices optimizados para búsquedas rápidas

## 💡 Funcionalidades Principales

### 1️⃣ Gestión de Productos

**Características:**
- ✅ CRUD completo (Crear, Leer, Actualizar, Eliminar)
- ✅ Búsqueda por nombre, SKU o código de barras
- ✅ Categorización de productos
- ✅ Control de stock mínimo con alertas
- ✅ Historial completo de movimientos (Kardex)
- ✅ Soft delete (eliminación lógica)

**Ejemplo de uso en C++:**
```cpp
ProductService productService;

Product product;
product.name = "Laptop Dell XPS 15";
product.sku = "DELL-XPS15-001";
product.barcode = "7501234567890";
product.salePrice = 1299.99;
product.currentStock = 10;

QString errorMessage;
if (productService.createProduct(product, errorMessage)) {
    qDebug() << "Producto creado con ID:" << product.id;
} else {
    qDebug() << "Error:" << errorMessage;
}
```

### 2️⃣ Importación desde Excel (REQUISITO CRÍTICO)

**🎯 Característica destacada: Mapeo flexible de columnas**

El orden de las columnas NO importa. El usuario puede:
1. Cargar cualquier archivo Excel
2. Ver las columnas detectadas
3. Mapear cada columna del Excel a un campo del sistema
4. Guardar la configuración como plantilla
5. Reutilizar plantillas en futuras importaciones

**Flujo de importación:**
```cpp
ExcelImportService importService;

// 1. Cargar archivo y detectar columnas
QStringList columns = importService.loadExcelFile("productos.xlsx");
// Resultado: ["Descripción", "Código", "Precio", "Existencia"]

// 2. Configurar mapeo (puede hacerse visualmente en QML)
QList<ExcelImportService::ColumnMapping> mappings;
mappings.append({"Descripción", "name", 0, true});
mappings.append({"Código", "sku", 1, true});
mappings.append({"Precio", "sale_price", 2, true});
mappings.append({"Existencia", "stock", 3, true});

// 3. Vista previa
auto preview = importService.getPreview("productos.xlsx", mappings, 10);
qDebug() << "Total filas:" << preview.totalRows;

// 4. Importar
auto result = importService.importProducts("productos.xlsx", mappings);
qDebug() << "Importados:" << result.importedRows;
qDebug() << "Errores:" << result.failedRows;
```

**Guardar plantilla:**
```cpp
QString error;
importService.saveTemplate("Mi Plantilla", mappings, error);

// Reutilizar más tarde
auto savedMappings = importService.loadTemplate("Mi Plantilla");
```

### 3️⃣ Sistema de Ventas

**Proceso completo de venta:**
1. Agregar productos al carrito
2. Calcular totales (subtotal, impuestos, descuentos)
3. Seleccionar método de pago
4. Generar número de factura automático
5. Actualizar stock automáticamente
6. Registrar movimientos en el Kardex
7. Generar comprobante en PDF

**Ejemplo:**
```cpp
SalesService salesService;

Sale sale;
sale.customerId = 1;
sale.paymentMethodId = 1; // Efectivo

// Agregar items
SaleItem item1;
item1.productId = 5;
item1.productName = "Laptop Dell XPS 15";
item1.quantity = 1;
item1.unitPrice = 1299.99;
item1.calculateSubtotal();
sale.items.append(item1);

// Calcular totales
sale.calculateTotals();

QString errorMessage;
if (salesService.createSale(sale, errorMessage)) {
    qDebug() << "Venta creada:" << sale.invoiceNumber;
    // Stock actualizado automáticamente
} else {
    qDebug() << "Error:" << errorMessage;
}
```

### 4️⃣ Generación de PDF para Comprobantes

**Dos formatos soportados:**
- 📄 **Formato A4 estándar** (para impresoras de oficina)
- 🧾 **Formato térmico** (58mm o 80mm, para tickets)

**Ejemplo:**
```cpp
PdfGeneratorService pdfService;

// Configurar datos del negocio
PdfGeneratorService::BusinessInfo info;
info.name = "Mi Tienda";
info.address = "Av. Principal 123";
info.phone = "(555) 123-4567";
info.taxId = "RUC: 12345678901";
pdfService.setBusinessInfo(info);

// Generar PDF estándar
pdfService.generateSaleReceipt(sale, "comprobante_001.pdf");

// Generar ticket térmico (80mm)
pdfService.generateThermalReceipt(sale, "ticket_001.pdf", 80);

// Imprimir directamente
pdfService.printReceipt(sale);
```

### 5️⃣ Soporte para Hardware

**Lectores de Código de Barras:**

Los lectores USB/Serial que emulan teclado son soportados automáticamente:

```cpp
BarcodeScannerHandler scanner;

connect(&scanner, &BarcodeScannerHandler::barcodeScanned, 
        [](const QString& barcode) {
    qDebug() << "Código escaneado:" << barcode;
    // Buscar producto y agregarlo al carrito
});

scanner.setEnabled(true);
```

**Desde QML:**
```qml
BarcodeScannerHandler {
    id: scanner
    enabled: true
    
    onBarcodeScanned: function(barcode) {
        // Buscar producto por código de barras
        searchProduct(barcode)
    }
}
```

### 6️⃣ Dashboard con Estadísticas

**Métricas en tiempo real:**
- 💰 Ventas del día y del mes
- 📊 Ticket promedio
- 📦 Total de productos en catálogo
- ⚠️ Productos con stock bajo

**Uso en QML:**
```qml
DashboardViewModel {
    id: dashboard
    Component.onCompleted: refresh()
}

Label {
    text: "$" + dashboard.todaySales.toFixed(2)
}

Label {
    text: dashboard.lowStockProducts + " productos requieren atención"
    visible: dashboard.lowStockProducts > 0
}
```

## 🎨 Interfaz de Usuario

### Material Design

La aplicación usa **Material Design** para una experiencia moderna:
- ✨ Animaciones suaves
- 🌓 Modo claro y oscuro (configurable)
- 📱 Diseño responsive
- 🎨 Paleta de colores consistente

### Navegación

**Menú lateral (Drawer)** con opciones:
- Dashboard
- Productos
- Ventas
- Inventario
- Clientes
- Reportes
- Importar Excel
- Configuración

## 🔧 Compilación y Configuración

### Requisitos

- **Qt 6.8+** (Open Source LGPL)
- **CMake 3.16+**
- **Compilador C++17** (MSVC, GCC, Clang)
- **QXlsx** (para importación Excel) - opcional

### Compilar en Windows

```bash
# 1. Clonar el repositorio
cd SistemaInventario

# 2. Crear directorio de compilación
mkdir build
cd build

# 3. Configurar con CMake
cmake -G "Ninja" -DCMAKE_BUILD_TYPE=Release ..

# 4. Compilar
cmake --build .

# 5. Ejecutar
./appSistemaInventario.exe
```

### Instalar QXlsx (Opcional, para Excel)

**Opción 1: vcpkg**
```bash
vcpkg install qxlsx
```

**Opción 2: Manual**
1. Descargar desde: https://github.com/QtExcel/QXlsx
2. Colocar en `thirdparty/QXlsx/`
3. Descomentar líneas en CMakeLists.txt

## 📝 Decisiones de Arquitectura

### ¿Por qué SQLite?

- ✅ Sin instalación de servidor
- ✅ Base de datos en un solo archivo
- ✅ Ideal para aplicaciones de escritorio
- ✅ Fácil respaldo (copiar archivo .db)
- ✅ Migración a PostgreSQL/MySQL es directa si se necesita

### ¿Por qué MVVM?

- ✅ Separación de interfaz y lógica
- ✅ Facilita testing automatizado
- ✅ Código más mantenible
- ✅ Patrón recomendado para Qt Quick

### ¿Por qué Repository Pattern?

- ✅ Encapsula acceso a datos
- ✅ Facilita cambio de base de datos
- ✅ Centraliza queries SQL
- ✅ Evita duplicación de código

### ¿Por qué Qt Quick + QML?

- ✅ Interfaz moderna y fluida
- ✅ Desarrollo rápido de UI
- ✅ Animaciones nativas
- ✅ Diseño declarativo

## 🚀 Roadmap / Mejoras Futuras

### Versión 1.1
- [ ] Módulo de compras (órdenes de compra)
- [ ] Gestión de proveedores
- [ ] Múltiples almacenes/sucursales
- [ ] Códigos QR para productos

### Versión 1.2
- [ ] Reportes avanzados (gráficos)
- [ ] Exportar a Excel desde el sistema
- [ ] Sistema de usuarios y permisos
- [ ] Auditoría de cambios

### Versión 2.0
- [ ] Aplicación móvil complementaria
- [ ] Sincronización en la nube
- [ ] API REST para integraciones
- [ ] Soporte multi-idioma

## 📄 Licencia

Este proyecto usa **Qt 6 Open Source (LGPL)**, lo cual permite:
- ✅ Uso comercial
- ✅ Distribución del ejecutable
- ⚠️ Debes enlazar Qt dinámicamente
- ⚠️ Cambios en Qt deben ser publicados

**Tu código de negocio (src/) puede ser propietario.**

## 🤝 Contribuciones

Para contribuir:
1. Fork el repositorio
2. Crea una rama: `git checkout -b feature/nueva-funcionalidad`
3. Commit: `git commit -m 'Agregar nueva funcionalidad'`
4. Push: `git push origin feature/nueva-funcionalidad`
5. Abre un Pull Request

## 📞 Soporte

Para preguntas o soporte:
- 📧 Email: soporte@sistemainventario.com
- 📚 Wiki: [GitHub Wiki](enlace-wiki)
- 🐛 Reportar bugs: [GitHub Issues](enlace-issues)

---

**¡Sistema listo para producción! 🎉**

Desarrollado con ❤️ usando Qt 6 y C++17
