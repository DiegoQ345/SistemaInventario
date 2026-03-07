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
│   │   └── Migraciones automáticas (schema v5)
│   ├── models/            # Modelos de dominio (POJOs)
│   │   ├── Product.h
│   │   ├── Sale.h
│   │   ├── Customer.h
│   │   └── StockMovement.h
│   ├── repositories/      # Acceso a datos (patrón Repository)
│   │   ├── ProductRepository.h/cpp
│   │   ├── SaleRepository.h/cpp
│   │   ├── CustomerRepository.h/cpp
│   │   └── TicketTemplateRepository.h/cpp  ← Plantillas de tickets
│   ├── services/          # Lógica de negocio
│   │   ├── ProductService.h/cpp
│   │   ├── SalesService.h/cpp
│   │   ├── ExcelImportService.h/cpp       ← Importación Excel
│   │   ├── PdfGeneratorService.h/cpp      ← PDF estándar A4
│   │   ├── PrintService.h/cpp             ← Sistema de impresión
│   │   ├── NotificationService.h/cpp      ← Notificaciones
│   │   └── AuthenticationService.h/cpp    ← Autenticación
│   ├── printing/          # Sistema de tickets personalizados
│   │   ├── TicketLayout.h/cpp             ← Parser de diseños JSON
│   │   ├── TicketRenderer.h/cpp           ← Renderizado a QPainter
│   │   └── TicketDynamicSection.h/cpp     ← Sección de productos
│   ├── viewmodels/        # ViewModels para MVVM
│   │   ├── DashboardViewModel.h/cpp
│   │   ├── ProductListModel.h/cpp
│   │   ├── SalesCartViewModel.h/cpp       ← Carrito de ventas
│   │   ├── PrintViewModel.h/cpp           ← Impresión/PDF
│   │   └── ExcelImportViewModel.h/cpp
│   └── utils/             # Utilidades
│       └── BarcodeScannerHandler.h/cpp
├── qml/                   # Interfaz de usuario
│   ├── pages/             # Páginas de la aplicación
│   │   ├── DashboardPage.qml
│   │   ├── ProductsPage.qml
│   │   ├── SalesPage.qml              ← Sistema de ventas completo
│   │   ├── TicketsPage.qml            ← Diseñador visual de tickets
│   │   ├── CustomersPage.qml
│   │   ├── ReportsPage.qml
│   │   └── SettingsPage.qml
│   └── components/        # Componentes reutilizables
│       ├── dialogs/
│       │   ├── PrintDialog.qml        ← Diálogo de impresión
│       │   ├── SaleSuccessDialog.qml
│       │   └── ConfirmDialog.qml
│       ├── Badge.qml
│       ├── PrimaryButton.qml
│       ├── SearchField.qml
│       ├── NotificationBar.qml
│       └── LoadingSpinner.qml
├── external/              # Dependencias externas
│   └── QXlsx/             # Librería para Excel
├── documentation/         # 📚 Documentación técnica
│   ├── README.md          # Índice de documentación
│   ├── ARQUITECTURA.md
│   ├── PRINTING_SYSTEM.md
│   ├── MVVM_ARCHITECTURE.md
│   └── build_log.txt      # Logs de compilación
├── Main.qml               # Punto de entrada QML
├── main.cpp               # Punto de entrada C++
├── CMakeLists.txt         # Configuración de compilación
└── vcpkg.json             # Dependencias (QXlsx)
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
- voucher_type: TEXT (BOLETA, FACTURA)
- customer_name: TEXT
- customer_ruc: TEXT (para facturas)
- customer_business_name: TEXT (razón social para facturas)
- customer_address: TEXT (para facturas)
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

**ticket_templates** (Plantillas de Tickets)
```sql
- id: INTEGER PRIMARY KEY
- name: TEXT UNIQUE (nombre de la plantilla)
- layout_json: TEXT (diseño completo en JSON)
- is_active: BOOLEAN (plantilla activa para impresión)
- created_at: DATETIME
- updated_at: DATETIME
```

**Estructura del layout_json:**
```json
{
  "size": {
    "width": 80,
    "height": 200
  },
  "elements": [
    {
      "type": "Text",
      "content": "{{businessName}}",
      "x": 5,
      "y": 10,
      "width": 70,
      "height": 8,
      "fontSize": 12,
      "alignment": "Center",
      "bold": true
    },
    {
      "type": "ItemsPlaceholder",
      "content": "{{Productos}}",
      "x": 5,
      "y": 50,
      "width": 70
    }
  ]
}
```

### Migraciones Automáticas

El sistema implementa un sistema de migraciones automático en **schema versión 5**:
- Al iniciar, verifica la versión del esquema
- Aplica migraciones pendientes automáticamente
- Garantiza integridad referencial (FOREIGN KEYS)
- Índices optimizados para búsquedas rápidas
- Tabla `ticket_templates` para almacenar diseños personalizados
- Campos adicionales en `sales` para datos de facturación completos

## 💡 Funcionalidades Principales

### 1️⃣ Gestión de Productos

**Características:**
- ✅ CRUD completo (Crear, Leer, Actualizar, Eliminar)
- ✅ Búsqueda por nombre, SKU o código de barras
- ✅ Categorización de productos
- ✅ Control de stock mínimo con alertas
- ✅ Historial completo de movimientos (Kardex)
- ✅ Soft delete (eliminación lógica)
- ✅ Importación masiva desde Excel con mapeo flexible
- ✅ Soporte para lectores de código de barras

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
3. Capturar datos de factura (RUC, razón social, dirección) si aplica
4. Seleccionar método de pago y tipo de comprobante (BOLETA/FACTURA)
5. Generar número de factura automático
6. Actualizar stock automáticamente
7. Registrar movimientos en el Kardex
8. Generar comprobante con diseño personalizado
9. Mostrar diálogo de éxito con opción de imprimir/guardar PDF

**Soporte de comprobantes:**
- 🧾 **BOLETA**: Para clientes sin RUC (datos básicos)
- 🧾 **FACTURA**: Para clientes con RUC (incluye razón social y dirección)

**Ejemplo:**
```cpp
SalesCartViewModel cartViewModel;

// Agregar productos al carrito
cartViewModel.addProduct(productId, quantity);
cartViewModel.updateQuantity(index, newQuantity);
cartViewModel.removeItem(index);

// Datos de factura (opcional, solo para FACTURA)
InvoiceData invoiceData;
invoiceData.ruc = "20123456789";
invoiceData.businessName = "Empresa SAC";
invoiceData.address = "Jr. Los Negocios 456";

// Procesar venta con datos de factura
cartViewModel.processSaleWithInvoiceData(
    customerId,
    paymentMethodId, 
    discount,
    invoiceData,
    isInvoice  // true = FACTURA, false = BOLETA
);

// El ViewModel emite señal saleCompleted con todos los datos
// que luego usa PrintDialog para generar el comprobante
```

**Carrito de compras (QML):**
```qml
SalesCartViewModel {
    id: cartViewModel
    
    onSaleCompleted: function(invoiceNumber, total, voucherType, items, subtotal, discount) {
        // Mostrar diálogo de éxito
        successDialog.invoiceNumber = invoiceNumber
        successDialog.total = total
        successDialog.voucherType = voucherType
        successDialog.open()
        
        // Abrir diálogo de impresión
        printDialog.preparePrint(invoiceNumber, total, voucherType, items, subtotal, discount)
    }
}
```

### 4️⃣ Sistema de Impresión y Tickets Personalizados

**🎨 Diseñador Visual de Tickets**

El sistema incluye un **editor WYSIWYG completo** para crear diseños de tickets personalizados sin código:

**Características del diseñador:**
- ✅ Drag & drop para posicionar elementos
- ✅ Redimensionamiento visual con handles
- ✅ Vista previa en tiempo real
- ✅ Variables dinámicas (nombre negocio, RUC, totales, etc.)
- ✅ Soporte para imágenes (logos)
- ✅ Sección de productos dinámica con auto-cálculo de altura
- ✅ Múltiples plantillas guardadas en base de datos
- ✅ Plantilla activa seleccionable

**Elementos soportados:**
- 📝 **Texto**: Con fuentes, tamaños y alineación personalizables
- ➖ **Líneas**: Separadores horizontales o verticales
- 🖼️ **Imágenes**: Logos y gráficos
- 📦 **Lista de productos**: Placeholder especial que se expande automáticamente

**Flujo de uso:**
1. Ir a página de "Tickets" en el sistema
2. Crear nuevo diseño o editar existente
3. Arrastrar elementos (texto, líneas, imágenes)
4. Configurar variables: `{{businessName}}`, `{{ruc}}`, `{{total}}`, etc.
5. Agregar placeholder de productos: `{{Productos}}`
6. Guardar diseño y marcar como activo
7. El sistema usará automáticamente el diseño activo al imprimir ventas

**Arquitectura de impresión:**
```cpp
// 1. TicketLayout: Parsea JSON del diseño (almacena medidas en MM)
TicketLayout layout;
layout.loadFromJson(templateJson);

// 2. TicketRenderer: Convierte MM a píxeles según DPI y renderiza
TicketRenderer renderer;
renderer.setLayout(layout);
renderer.setDeviceDpi(printer->resolution(), printer->resolution());

// 3. TicketDynamicSection: Calcula altura de lista de productos
TicketDynamicSection dynamicSection(sale.items, renderer.pixelsPerMM());
qreal finalY = dynamicSection.render(&painter, startY);

// 4. PrintService: Orquesta todo el proceso
PrintService printService;
printService.printCustomTicket(sale, invoiceData); // Imprime
printService.generateCustomTicketPdf(sale, invoiceData, "ticket.pdf"); // PDF
```

**Variables disponibles:**
- `{{businessName}}` - Nombre del negocio
- `{{ruc}}` - RUC/NIT del negocio
- `{{address}}` - Dirección
- `{{phone}}` - Teléfono
- `{{invoiceNumber}}` - Número de factura/boleta
- `{{date}}` - Fecha de emisión
- `{{time}}` - Hora de emisión
- `{{customerName}}` - Nombre del cliente
- `{{customerRuc}}` - RUC del cliente (facturas)
- `{{customerBusinessName}}` - Razón social (facturas)
- `{{customerAddress}}` - Dirección del cliente (facturas)
- `{{voucherType}}` - FACTURA o BOLETA
- `{{subtotal}}` - Subtotal
- `{{tax}}` - IGV/IVA
- `{{discount}}` - Descuento
- `{{total}}` - Total final
- `{{Productos}}` - Placeholder para lista de productos (auto-expansión)

**Configuración DPI:**
- **Estándar de impresión**: 300 DPI (STANDARD_DPI constante)
- **Conversión automática**: Diseños en MM → Píxeles según DPI del dispositivo
- **Font scaling**: Factor de /3 aplicado desde diseñador a renderizado

**Generación de PDF estándar:**
```cpp
PdfGeneratorService pdfService;

// Configurar datos del negocio
PdfGeneratorService::BusinessInfo info;
info.name = "Mi Tienda";
info.address = "Av. Principal 123";
info.phone = "(555) 123-4567";
info.taxId = "RUC: 12345678901";
pdfService.setBusinessInfo(info);

// Generar PDF estándar A4
pdfService.generateSaleReceipt(sale, "comprobante_001.pdf");
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

**Impresoras:**
- ✅ **Impresoras térmicas**: Tickets con diseños personalizados
- ✅ **Impresoras de oficina**: PDFs estándar A4
- ✅ **Configuración automática**: El sistema detecta resolución DPI
- ✅ **Vista previa**: Antes de imprimir se muestra preview

### 6️⃣ Sistema de Notificaciones

**Barra de notificaciones flotante** para mensajes al usuario:

**Desde QML:**
```qml
NotificationBar {
    id: notificationBar
    anchors.top: parent.top
}

// Mostrar notificación
notificationBar.show("Producto guardado exitosamente", "success")
notificationBar.show("Error al procesar venta", "error")
notificationBar.show("Stock bajo detectado", "warning")
notificationBar.show("Procesando importación...", "info")
```

**Tipos de notificación:**
- ✅ `success` - Verde, operaciones exitosas
- ⚠️ `warning` - Amarillo, advertencias
- ❌ `error` - Rojo, errores
- ℹ️ `info` - Azul, información general

### 7️⃣ Dashboard con Estadísticas

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
- 📊 Dashboard
- 📦 Productos
- 💰 Ventas (con carrito completo)
- 📋 Inventario (movimientos de stock)
- 👥 Clientes
- 📈 Reportes
- 🎫 Tickets (diseñador visual)
- 📥 Importar Excel
- ⚙️ Configuración
- 👤 Perfil de Usuario
- 🔐 Gestión de Usuarios

### Componentes Reutilizables

El sistema incluye una biblioteca de componentes Material Design:

**Botones:**
- `PrimaryButton.qml` - Botón principal (acción primaria)
- `SecondaryButton.qml` - Botón secundario
- `OutlinedButton.qml` - Botón con borde

**Formularios:**
- `SearchField.qml` - Campo de búsqueda con icono
- `QuantitySpinBox.qml` - Selector de cantidad para ventas

**Diálogos:**
- `ConfirmDialog.qml` - Confirmación de acciones
- `ErrorDialog.qml` - Mostrar errores
- `SuccessDialog.qml` - Confirmación de éxito
- `PrintDialog.qml` - Impresión y generación de PDF
- `SaleSuccessDialog.qml` - Éxito de venta con opciones

**Otros:**
- `Badge.qml` - Insignias numéricas (ej: items en carrito)
- `LoadingSpinner.qml` - Indicador de carga
- `NotificationBar.qml` - Barra de notificaciones
- `StatCard.qml` - Tarjetas de estadísticas (Dashboard)
- `CartItemDelegate.qml` - Item de carrito de ventas

Todos documentados en `qml/components/USAGE_GUIDE.md`

## 🔧 Compilación y Configuración

### Requisitos

- **Qt 6.10.1+** (Open Source LGPL)
- **CMake 3.16+**
- **Compilador C++17** (MinGW 13.1.0 para Windows)
- **QXlsx** (para importación Excel) - incluido en `external/`
- **Ninja** o **Visual Studio** (generador de build)

### Compilar en Windows con Qt Creator

```bash
# 1. Abrir Qt Creator
# 2. File → Open File or Project → CMakeLists.txt
# 3. Configurar kit (Desktop Qt 6.10.1 MinGW 64-bit)
# 4. Build → Build Project
# 5. Run → Run (Ctrl+R)
```

### Compilar desde línea de comandos

```bash
# 1. Clonar el repositorio
git clone https://github.com/tu-usuario/SistemaInventario.git
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

### Dependencias

**QXlsx (incluida):**
La librería QXlsx está incluida en `external/QXlsx/` y se compila automáticamente con el proyecto.

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

### En Desarrollo
- [ ] Corrección de bug de doble-wrapping en variables de tickets
- [ ] Variables faltantes para facturas (customerBusinessName, customerAddress)
- [ ] Unificación de constantes DPI entre QML y C++

### Versión 1.1
- [ ] Módulo de compras (órdenes de compra)
- [ ] Gestión de proveedores
- [ ] Múltiples almacenes/sucursales
- [ ] Códigos QR para productos
- [ ] Sistema completo de permisos por rol

### Versión 1.2
- [ ] Reportes avanzados (gráficos)
- [ ] Exportar a Excel desde el sistema
- [ ] Auditoría completa de cambios
- [ ] Dashboard con gráficos de tendencias
- [ ] Backup automático de base de datos

### Versión 2.0
- [ ] Aplicación móvil complementaria
- [ ] Sincronización en la nube
- [ ] API REST para integraciones
- [ ] Soporte multi-idioma
- [ ] Facturación electrónica (SUNAT/SRI)

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

## � Documentación Adicional

Para documentación técnica detallada, consulta la carpeta `documentation/`:

- **Arquitectura**: MVVM, componentes, servicios
- **Sistema de impresión**: TicketLayout, TicketRenderer, PrintService
- **Base de datos**: Esquema, migraciones, versiones
- **Flujos de trabajo**: Ventas, impresión, notificaciones
- **Fixes aplicados**: Historial de correcciones y mejoras

## 📞 Soporte

Para preguntas o soporte:
- 📧 Email: soporte@sistemainventario.com
- 📚 Documentación: `documentation/README.md`
- 🐛 Reportar bugs: GitHub Issues

---

**Desarrollado con ❤️ usando Qt 6.10.1 y C++17**


