# 🏗️ Arquitectura del Sistema de Diseño de Tickets

**Documentación técnica completa del flujo de diseño e impresión**

---

## 📊 Diagrama de Arquitectura General

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CAPA DE PRESENTACIÓN (QML)                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐      ┌──────────────┐      ┌──────────────┐      │
│  │TicketsPage  │      │  SalesPage   │      │ PrintDialog  │      │
│  │  (Editor)   │      │  (Ventas)    │      │(Configuración│      │
│  │             │      │              │      │  Impresión)  │      │
│  └──────┬──────┘      └──────┬───────┘      └──────┬───────┘      │
│         │                    │                     │               │
│         │ Guarda diseño      │ Procesa venta       │ Imprime      │
│         ▼                    ▼                     ▼               │
├─────────────────────────────────────────────────────────────────────┤
│                         CAPA DE SERVICIOS (C++)                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌────────────────┐    ┌─────────────┐    ┌──────────────┐        │
│  │TicketTemplate  │    │SalesCart    │    │PrintViewModel│        │
│  │  Repository    │    │  ViewModel  │    │              │        │
│  │                │    │             │    │              │        │
│  │ - save()       │    │ - process() │    │ - printPdf() │        │
│  │ - load()       │    │             │    │ - print()    │        │
│  │ - getActive()  │    │             │    │              │        │
│  └────────┬───────┘    └──────┬──────┘    └──────┬───────┘        │
│           │                   │                    │                │
│           ▼                   ▼                    ▼                │
│  ┌─────────────────────────────────────────────────────────┐       │
│  │              PrintService + PdfGeneratorService         │       │
│  │                                                          │       │
│  │  - drawCustomTicket()                                   │       │
│  │  - generateCustomTicketPdf()                            │       │
│  │  - replaceVariables()                                   │       │
│  └─────────────────────────────────────────────────────────┘       │
│                              │                                      │
├──────────────────────────────┼──────────────────────────────────────┤
│                              ▼                                      │
│                   ┌───────────────────┐                             │
│                   │  CAPA DE DATOS    │                             │
│                   ├───────────────────┤                             │
│                   │  SQLite Database  │                             │
│                   │                   │                             │
│                   │ ticket_templates  │                             │
│                   │ sales             │                             │
│                   │ sale_items        │                             │
│                   └───────────────────┘                             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flujo Completo: Desde Diseño hasta Impresión

### 1️⃣ Fase: Diseño del Ticket

```
Usuario abre TicketsPage.qml
↓
Selecciona tamaño (80mm x 200mm)
↓
Arrastra/redimensiona elementos
  - Logo (imagen)
  - Nombre negocio (texto)
  - Líneas separadoras
  - Variables dinámicas ({{total}}, {{customerName}})
↓
Guarda diseño
↓
TicketTemplateRepository::saveTemplate()
  ↓
  Serializa a JSON:
  {
    "size": { "width": 80, "height": 200 },
    "elements": [
      { "id": "logo", "type": "image", "x": 10, "y": 5, ... },
      { "id": "total", "type": "text", "x": 10, "y": 180, ... }
    ]
  }
  ↓
  INSERT INTO ticket_templates (name, layout_json)
  ↓
  Establece como diseño activo
```

### 2️⃣ Fase: Proceso de Venta

```
Usuario en SalesPage.qml
↓
Agrega productos al carrito
↓
Llena datos de cliente
  - Nombre
  - RUC (si es factura)
  - Razón social (si es factura)
↓
Click "Procesar Venta"
↓
SalesCartViewModel::processSale()
  ↓
  Validaciones:
    - Stock disponible ✓
    - Cliente válido ✓
    - Método de pago ✓
  ↓
  SalesService::createSale()
    ↓
    BEGIN TRANSACTION
      INSERT INTO sales (...)
      INSERT INTO sale_items (...)
      UPDATE products SET stock = stock - quantity
    COMMIT
  ↓
  Emite: saleProcessed(saleId, invoiceNumber)
```

### 3️⃣ Fase: Apertura de Diálogo de Impresión

```
SalesPage recibe señal saleProcessed
↓
Abre SaleSuccessDialog
  - Muestra resumen de venta
  - Botón "Imprimir"
↓
Usuario click "Imprimir"
↓
Abre PrintDialog
  ↓
  Pasa datos:
    - invoiceNumber: "B001-00001234"
    - customerName: "Juan Pérez"
    - items: [{ productName, quantity, unitPrice, subtotal }]
    - subtotal: 100.00
    - discount: 0.00
    - total: 100.00
    - voucherType: PrintViewModel.Boleta
  ↓
  PrintDialog.Component.onCompleted
    loadActiveTemplate()
      ↓
      TicketTemplateRepository::getActiveTemplate()
        ↓
        SELECT * FROM ticket_templates WHERE is_active = 1
        ↓
        Retorna: { id: 1, name: "Diseño Estándar", layoutJson: "..." }
      ↓
      Parsea JSON y carga en templateElements
```

### 4️⃣ Fase: Configuración de Impresión

```
PrintDialog muestra:
  ┌─────────────────────────┐
  │ Configuración Impresión │
  ├─────────────────────────┤
  │ Impresora: [Térmica POS]│
  │ Diseño: [Diseño Estándar]│
  │ Tamaño: 80mm x 200mm    │
  │                         │
  │ [Vista Previa] [PDF]    │
  │         [Imprimir]      │
  └─────────────────────────┘

Usuario selecciona:
  - Impresora destino
  - Diseño de ticket (si hay múltiples)
  
Auto-configura:
  - paperSize según diseño
  - 80mm → PrintViewModel.Thermal80mm
  - 58mm → PrintViewModel.Thermal58mm
```

### 5️⃣ Fase: Generación de PDF

```
Usuario click "Generar PDF"
↓
PrintDialog::generateSalePdf()
  ↓
  Prepara datos:
    var saleData = {
      id: 0,
      invoiceNumber: "B001-00001234",
      customerName: "Juan Pérez",
      items: [
        { productName: "Producto 1", quantity: 2, unitPrice: 25, subtotal: 50 },
        { productName: "Producto 2", quantity: 1, unitPrice: 50, subtotal: 50 }
      ],
      subtotal: 100.00,
      discount: 0.00,
      total: 100.00,
      createdAt: "2026-03-02T10:30:00"
    }
    
    var invoiceData = {
      ruc: "20123456789",           // Si es factura
      businessName: "EMPRESA S.A.C.", // Si es factura
      address: "Av. Principal 123"  // Si es factura
    }
    
    var layoutJson = JSON.stringify({
      size: { width: 80, height: 200 },
      elements: templateElements
    })
  ↓
  PrintService::generateCustomTicketPdf(saleData, voucherType, invoiceData, layoutJson, outputPath)
```

### 6️⃣ Fase: Renderizado en C++

```cpp
PrintService::generateCustomTicketPdf() {
    // 1. Parsear JSON
    QJsonDocument doc = QJsonDocument::fromJson(layoutJson.toUtf8());
    QJsonObject layoutObj = doc.object();
    
    double ticketWidth = layoutObj["size"]["width"].toDouble();   // 80
    double ticketHeight = layoutObj["size"]["height"].toDouble(); // 200
    QJsonArray elements = layoutObj["elements"].toArray();
    
    // 2. Configurar PDF Writer
    QPdfWriter pdfWriter(outputPath);
    pdfWriter.setPageSize(QPageSize(QSizeF(80, 200), QPageSize::Millimeter));
    pdfWriter.setPageMargins(QMarginsF(0, 0, 0, 0));
    pdfWriter.setResolution(300);  // 300 DPI para alta calidad
    
    // 3. Calcular factor de conversión
    QPainter painter;
    painter.begin(&pdfWriter);
    
    double pixelsPerMM = painter.device()->logicalDpiX() / 25.4;
    // logicalDpiX() = 300 → pixelsPerMM = 300 / 25.4 = 11.81
    
    // 4. Primer pass: Calcular altura de items dinámicos
    double itemsStartY = 0;
    double itemsHeight = 0;
    
    for (element in elements) {
        if (element["id"] == "itemsHeader") {
            itemsStartY = element["y"].toDouble() * pixelsPerMM;
            itemsWidth = element["width"].toDouble() * pixelsPerMM;
            
            // Calcular altura real de los items con word wrap
            for (item in sale.items) {
                QFont font("Arial", 8);
                QFontMetrics fm(font);
                QRect rect = fm.boundingRect(
                    0, 0, itemsWidth, 1000,
                    Qt::AlignLeft | Qt::TextWordWrap,
                    item.productName
                );
                itemsHeight += rect.height() + spacing;
            }
        }
    }
    
    // 5. Segundo pass: Dibujar elementos
    for (element in elements) {
        QString type = element["type"].toString();
        double x = element["x"].toDouble() * pixelsPerMM;
        double y = element["y"].toDouble() * pixelsPerMM;
        double width = element["width"].toDouble() * pixelsPerMM;
        double height = element["height"].toDouble() * pixelsPerMM;
        
        // Ajustar Y si está después del área de items
        if (y > itemsStartY) {
            y += itemsHeight;  // Desplazar hacia abajo
        }
        
        if (type == "text") {
            QString content = element["content"].toString();
            content = replaceVariables(content, sale, invoiceData);
            // "Cliente: {{customerName}}" → "Cliente: Juan Pérez"
            
            int fontSize = element["fontSize"].toInt();
            bool bold = element["bold"].toBool();
            QString align = element["align"].toString();
            
            QFont font("Arial", fontSize);
            font.setBold(bold);
            painter.setFont(font);
            
            Qt::Alignment alignment = Qt::AlignLeft;
            if (align == "center") alignment = Qt::AlignHCenter;
            if (align == "right") alignment = Qt::AlignRight;
            
            painter.drawText(QRectF(x, y, width, height), alignment, content);
        }
        else if (type == "line") {
            painter.drawLine(QPointF(x, y), QPointF(x + width, y));
        }
        else if (type == "image") {
            QString imagePath = element["content"].toString();
            QImage image(imagePath);
            painter.drawImage(QRectF(x, y, width, height), image);
        }
    }
    
    // 6. Dibujar items de venta
    double currentY = itemsStartY;
    for (item in sale.items) {
        painter.drawText(x, currentY, item.productName);
        currentY += lineHeight;
        
        painter.drawText(x + 5, currentY, 
            QString("%1 x S/ %2 = S/ %3")
                .arg(item.quantity)
                .arg(item.unitPrice)
                .arg(item.subtotal));
        currentY += lineHeight + spacing;
    }
    
    painter.end();
    
    return true;  // PDF generado exitosamente
}
```

### 7️⃣ Fase: Impresión Directa

```
Usuario click "Imprimir"
↓
PrintViewModel::printCustomTicket()
  ↓
  Misma lógica que PDF pero:
    QPrinter printer(QPrinter::HighResolution);
    printer.setPrinterName(m_defaultPrinter);  // "EPSON TM-T20III"
    printer.setPageSize(QPageSize(80, 200, QPageSize::Millimeter));
    
    QPainter painter;
    painter.begin(&printer);
    drawCustomTicket(painter, sale, ...);
    painter.end();
  ↓
  Envía directamente a la impresora
```

---

## 🔤 Sistema de Variables Dinámicas

### Variables Soportadas

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `{{businessName}}` | Nombre del negocio | "Tienda XYZ" |
| `{{ruc}}` | RUC del negocio | "20123456789" |
| `{{address}}` | Dirección del negocio | "Av. Principal 123" |
| `{{phone}}` | Teléfono | "(01) 123-4567" |
| `{{email}}` | Email | "ventas@tienda.com" |
| `{{invoiceNumber}}` | Número de comprobante | "B001-00001234" |
| `{{voucherType}}` | Tipo | "BOLETA" o "FACTURA" |
| `{{customerName}}` | Cliente | "Juan Pérez" |
| `{{customerRuc}}` | RUC del cliente | "10123456789" |
| `{{customerBusinessName}}` | Razón social | "EMPRESA S.A.C." |
| `{{customerAddress}}` | Dirección cliente | "Jr. Comercio 456" |
| `{{datetime}}` | Fecha y hora | "02/03/2026 10:30" |
| `{{date}}` | Solo fecha | "02/03/2026" |
| `{{time}}` | Solo hora | "10:30" |
| `{{subtotal}}` | Subtotal | "100.00" |
| `{{discount}}` | Descuento | "0.00" |
| `{{tax}}` | IGV/Impuesto | "18.00" |
| `{{total}}` | Total | "118.00" |

### Función de Reemplazo (C++)

```cpp
QString PrintService::replaceVariables(const QString& text, 
                                       const Sale& sale,
                                       VoucherType type,
                                       const InvoiceData& invoiceData) {
    QString result = text;
    
    // Negocio
    result.replace("{{businessName}}", m_companyName);
    result.replace("{{ruc}}", m_companyRuc);
    result.replace("{{address}}", m_companyAddress);
    result.replace("{{phone}}", m_companyPhone);
    result.replace("{{email}}", m_companyEmail);
    
    // Comprobante
    QString voucherTypeStr = (type == FACTURA) ? "FACTURA" : "BOLETA";
    result.replace("{{voucherType}}", voucherTypeStr);
    result.replace("{{invoiceNumber}}", sale.invoiceNumber);
    
    // Fechas
    result.replace("{{date}}", sale.createdAt.toString("dd/MM/yyyy"));
    result.replace("{{datetime}}", sale.createdAt.toString("dd/MM/yyyy hh:mm"));
    result.replace("{{time}}", sale.createdAt.toString("hh:mm"));
    
    // Cliente
    result.replace("{{customerName}}", sale.customerName);
    result.replace("{{customerRuc}}", invoiceData.ruc);
    result.replace("{{customerBusinessName}}", invoiceData.businessName);
    result.replace("{{customerAddress}}", invoiceData.address);
    
    // Totales
    result.replace("{{subtotal}}", QString::number(sale.subtotal, 'f', 2));
    result.replace("{{discount}}", QString::number(sale.discount, 'f', 2));
    result.replace("{{tax}}", QString::number(sale.tax, 'f', 2));
    result.replace("{{total}}", QString::number(sale.total, 'f', 2));
    
    return result;
}
```

---

## 📐 Sistema de Coordenadas y Conversión

### Unidades de Medida

```
DISEÑADOR (QML)          IMPRESIÓN (C++)
milímetros (mm)    →     píxeles (px)

Conversión:
pixelsPerMM = DPI / 25.4

Pantalla (96 DPI):
pixelsPerMM = 96 / 25.4 = 3.78

PDF (300 DPI):
pixelsPerMM = 300 / 25.4 = 11.81

Térmica (203 DPI):
pixelsPerMM = 203 / 25.4 = 7.99
```

### Ejemplo de Conversión

```
Elemento en diseñador:
{
  "x": 10,      // mm
  "y": 50,      // mm
  "width": 60,  // mm
  "height": 8   // mm
}

En QML (96 DPI):
x = 10 * 3.78 = 37.8 px
y = 50 * 3.78 = 189 px
width = 60 * 3.78 = 226.8 px
height = 8 * 3.78 = 30.24 px

En PDF (300 DPI):
x = 10 * 11.81 = 118.1 px
y = 50 * 11.81 = 590.5 px
width = 60 * 11.81 = 708.6 px
height = 8 * 11.81 = 94.48 px
```

### Precisión

```
QML almacena: 1 decimal (10.5 mm)
JSON guarda: "x": 10.5
C++ recibe: 10.5mm * pixelsPerMM

Error máximo: ±0.05mm = ±0.6px @ 300 DPI
              (imperceptible al ojo humano)
```

---

## 🗄️ Estructura de la Base de Datos

### Tabla: ticket_templates

```sql
CREATE TABLE ticket_templates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,          -- "Diseño Estándar Boleta"
    layout_json TEXT NOT NULL,          -- JSON con elementos
    is_active INTEGER DEFAULT 0,        -- 1 = diseño activo
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_ticket_templates_active ON ticket_templates(is_active);
CREATE UNIQUE INDEX idx_ticket_templates_name ON ticket_templates(name);
```

### Ejemplo de layout_json

```json
{
  "version": "1.0",
  "size": {
    "width": 80,
    "height": 200
  },
  "elements": [
    {
      "id": "logo",
      "type": "image",
      "label": "Logo",
      "x": 10,
      "y": 5,
      "width": 60,
      "height": 30,
      "content": "file:///C:/logo.png",
      "fontSize": 12,
      "bold": false,
      "align": "center"
    },
    {
      "id": "businessName",
      "type": "text",
      "label": "Nombre del Negocio",
      "x": 10,
      "y": 40,
      "width": 60,
      "height": 8,
      "content": "{{businessName}}",
      "fontSize": 14,
      "bold": true,
      "align": "center"
    },
    {
      "id": "separator1",
      "type": "line",
      "label": "Línea Separadora 1",
      "x": 5,
      "y": 80,
      "width": 70,
      "height": 1
    },
    {
      "id": "itemsHeader",
      "type": "text",
      "label": "[ITEMS]",
      "x": 10,
      "y": 115,
      "width": 60,
      "height": 6,
      "content": "{{Productos}}",
      "fontSize": 8,
      "bold": false,
      "align": "left"
    },
    {
      "id": "total",
      "type": "text",
      "label": "Total",
      "x": 10,
      "y": 178,
      "width": 60,
      "height": 8,
      "content": "TOTAL: S/ {{total}}",
      "fontSize": 12,
      "bold": true,
      "align": "right"
    }
  ]
}
```

---

## 🔧 Configuración del Sistema

### Archivo: main.cpp

```cpp
int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    
    // Registrar tipos para QML
    qmlRegisterType<PrintViewModel>("SistemaInventario", 1, 0, "PrintViewModel");
    qmlRegisterType<TicketTemplateRepository>("SistemaInventario", 1, 0, "TicketTemplateRepository");
    qmlRegisterType<PrintService>("SistemaInventario", 1, 0, "PrintService");
    
    // Configurar servicios globales
    PrintService* printService = new PrintService(&app);
    printService->setCompanyInfo(
        "Tienda XYZ",           // businessName
        "Jr. Comercio 123",     // address
        "(01) 123-4567",        // phone
        "ventas@tienda.com",    // email
        "20123456789"           // ruc
    );
    
    // Hacer accesible a toda la app
    qmlEngine.rootContext()->setContextProperty("globalPrintService", printService);
    
    return app.exec();
}
```

---

## 📊 Métricas del Sistema

### Rendimiento

| Operación | Tiempo | Detalles |
|-----------|--------|----------|
| Cargar diseño | <50ms | Lectura de BD + parse JSON |
| Guardar diseño | <100ms | Serializar JSON + INSERT |
| Generar PDF | 200-500ms | Depende de elementos e imágenes |
| Imprimir directo | 1-3s | Envío a spooler + impresión física |

### Límites

| Recurso | Límite | Notas |
|---------|--------|-------|
| Elementos por diseño | Ilimitado | Recomendado: <50 |
| Tamaño de imagen | 5 MB | Para carga rápida |
| Tamaños de ticket | 5 predefinidos | 58mm o 80mm ancho |
| Altura de ticket | Ilimitada | Típico: 200-297mm |
| Resolución PDF | 300 DPI | Configurable |

---

## 🧩 Componentes Reutilizables

### TicketsPage.qml
- **Responsabilidad:** Editor visual de tickets
- **Entrada:** ticketElements, ticketWidth, ticketHeight
- **Salida:** JSON guardado en BD
- **Líneas de código:** ~2,316

### PrintDialog.qml
- **Responsabilidad:** Configurar impresión
- **Entrada:** Datos de venta, diseño activo
- **Salida:** PDF o impresión directa
- **Líneas de código:** ~834

### PrintService.cpp
- **Responsabilidad:** Renderizado y generación
- **Entrada:** Sale, VoucherType, layoutJson
- **Salida:** PDF o envío a impresora
- **Líneas de código:** ~775

### TicketTemplateRepository
- **Responsabilidad:** CRUD de diseños
- **Entrada:** name, layoutJson
- **Salida:** Templates desde BD
- **Métodos:** save, load, delete, getActive

---

## ✅ Casos de Uso Completos

### Caso 1: Primera vez - Sin diseño

```
1. Usuario abre SalesPage
2. Completa venta
3. Click "Imprimir"
4. PrintDialog se abre
5. ⚠️ No hay diseño activo
6. Mensaje: "Ve a Diseñador de Tickets para crear uno"
7. Usuario navega a TicketsPage
8. Crea diseño desde plantilla
9. Guarda como "Diseño Estándar"
10. Se marca automáticamente como activo
11. Regresa a ventas, ahora puede imprimir
```

### Caso 2: Usuario avanzado - Múltiples diseños

```
1. Usuario tiene 3 diseños:
   - "Boleta Estándar" (activo)
   - "Factura Estándar"
   - "Ticket Promocional"
   
2. En PrintDialog puede seleccionar:
   ComboBox: [Boleta Estándar ▼]
            [Factura Estándar   ]
            [Ticket Promocional ]
   
3. Al cambiar, auto-configura:
   - Tamaño de papel
   - Elementos específicos
   
4. Cada diseño se renderiza independiente
```

### Caso 3: Modificar diseño existente

```
1. TicketsPage → Botón "Cargar"
2. Selecciona "Diseño Estándar"
3. Modifica posición del logo
4. Agrega campo de email
5. Guarda (sobrescribe o crea nuevo)
6. Diseño actualizado se usa en próximas impresiones
```

---

**Documentado por:** GitHub Copilot  
**Fecha:** 2 de Marzo de 2026  
**Versión del Sistema:** 1.0
