# ARQUITECTURA.md - Documentación Técnica Detallada

## 🏛️ Principios de Arquitectura

### SOLID Principles Aplicados

**Single Responsibility Principle (SRP)**
- Cada clase tiene una única responsabilidad
- `DatabaseManager`: Solo gestión de BD
- `ProductService`: Solo lógica de productos
- `ProductRepository`: Solo acceso a datos de productos

**Open/Closed Principle (OCP)**
- Abierto para extensión, cerrado para modificación
- Nuevos tipos de movimiento: solo agregar en BD
- Nuevos métodos de pago: configurables en BD

**Dependency Inversion Principle (DIP)**
- Servicios dependen de abstracciones (interfaces conceptuales)
- ViewModels dependen de Servicios, no de Repositorios
- Facilita testing con mocks

### Clean Architecture

```
┌──────────────────────────────────────┐
│   UI Layer (QML)                     │  ← Frameworks & Drivers
├──────────────────────────────────────┤
│   ViewModels                         │  ← Interface Adapters
├──────────────────────────────────────┤
│   Services (Business Logic)          │  ← Use Cases
├──────────────────────────────────────┤
│   Models (Entities)                  │  ← Enterprise Business Rules
└──────────────────────────────────────┘
```

## 🔄 Flujo de Datos (Data Flow)

### Lectura de Datos (Query)

```
QML Component
    ↓ llama método
ViewModel (expone propiedades Qt)
    ↓ usa
Service (lógica de negocio)
    ↓ consulta
Repository (acceso a datos)
    ↓ ejecuta SQL
Database (SQLite)
```

**Ejemplo concreto:**
```
ProductsPage.qml
    → ProductListModel.loadProducts()
        → ProductService.getAllProducts()
            → ProductRepository.findAll()
                → SELECT * FROM products
```

### Escritura de Datos (Command)

```
QML Component (botón "Guardar")
    ↓ invoca
ViewModel (método Q_INVOKABLE)
    ↓ valida y llama
Service (valida negocio, transacción)
    ↓ persiste
Repository (INSERT/UPDATE)
    ↓ ejecuta
Database
    ← emite señal (success/error)
ViewModel
    ← actualiza propiedades
QML (re-renderiza)
```

## 🧩 Patrones de Diseño Utilizados

### 1. Singleton (DatabaseManager)

**¿Por qué?**
- Una sola conexión a la base de datos
- Thread-safe con QMutex
- Acceso global sin variables globales

```cpp
DatabaseManager& db = DatabaseManager::instance();
```

### 2. Repository Pattern

**¿Por qué?**
- Encapsula lógica de acceso a datos
- Facilita testing (mock repositories)
- Independencia de la BD

```cpp
class ProductRepository {
    // Interfaz clara de acceso a datos
    int create(Product& product);
    std::optional<Product> findById(int id);
    QList<Product> findAll();
};
```

### 3. Service Layer Pattern

**¿Por qué?**
- Centraliza lógica de negocio
- Orquesta múltiples repositorios
- Maneja transacciones

```cpp
class ProductService {
    // Lógica de negocio compleja
    bool createProduct(...) {
        // 1. Validar
        // 2. Guardar en repo
        // 3. Registrar movimiento de stock
        // 4. Emitir señales
    }
};
```

### 4. MVVM (Model-View-ViewModel)

**¿Por qué?**
- Separación UI-Lógica
- Data binding automático con Qt properties
- Testeable

```cpp
class ProductListModel : public QAbstractListModel {
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    // QML puede observar cambios automáticamente
};
```

### 5. Observer Pattern (Qt Signals & Slots)

**¿Por qué?**
- Comunicación desacoplada
- Event-driven architecture

```cpp
// Service emite evento
emit productCreated(productId);

// ViewModel lo escucha
connect(service, &ProductService::productCreated, 
        this, &ProductListModel::refresh);
```

## 🔒 Thread Safety

### DatabaseManager con Mutex

```cpp
bool DatabaseManager::beginTransaction() {
    QMutexLocker locker(&m_mutex);  // Automático lock/unlock
    return m_database.transaction();
}
```

**¿Por qué es importante?**
- Qt QML puede ejecutar en múltiples hilos
- Previene condiciones de carrera
- Garantiza consistencia de datos

## 🗃️ Gestión de Transacciones

### Patrón de Transacción

```cpp
// Iniciar
DatabaseManager::instance().beginTransaction();

try {
    // Múltiples operaciones
    repository.create(product);
    movementRepository.create(movement);
    
    // Confirmar
    DatabaseManager::instance().commit();
} catch (...) {
    // Revertir en caso de error
    DatabaseManager::instance().rollback();
}
```

**Casos de uso:**
- Venta: actualizar stock + crear venta + items
- Cancelación: revertir stock + actualizar estado

## 📊 Manejo de Errores

### Estrategia Multinivel

**1. Nivel Repository: Errores de BD**
```cpp
if (!query.exec()) {
    qCritical() << "Error SQL:" << query.lastError().text();
    return 0;  // Indicador de fallo
}
```

**2. Nivel Service: Errores de Negocio**
```cpp
bool ProductService::createProduct(Product& p, QString& error) {
    if (!validateProduct(p, error)) {
        return false;  // error contiene mensaje
    }
    // ...
}
```

**3. Nivel ViewModel: Errores UI**
```cpp
signals:
    void errorOccurred(const QString& message);
```

**4. Nivel QML: Mostrar al Usuario**
```qml
Connections {
    target: productModel
    function onErrorOccurred(message) {
        errorDialog.text = message
        errorDialog.open()
    }
}
```

## 🎯 Optimizaciones de Rendimiento

### 1. Índices de Base de Datos

```sql
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_stock_movements_product ON stock_movements(product_id);
```

**Impacto:** Búsquedas 10-100x más rápidas

### 2. Lazy Loading en QML

```qml
ListView {
    model: productModel
    delegate: Loader {
        asynchronous: true  // No bloquea UI
        sourceComponent: productDelegate
    }
}
```

### 3. Prepared Statements

```cpp
QSqlQuery query(db);
query.prepare("SELECT * FROM products WHERE id = :id");
query.bindValue(":id", productId);
// Previene SQL injection + es más rápido
```

### 4. QAbstractListModel para Grandes Listas

```cpp
// Mejor que QList<QVariant> para QML
class ProductListModel : public QAbstractListModel {
    // Qt optimiza el rendering automáticamente
};
```

## 🧪 Testing Strategy

### Unit Tests (Recomendado)

```cpp
// test_ProductService.cpp
TEST_F(ProductServiceTest, CreateProduct_ValidData_ReturnsSuccess) {
    ProductService service;
    Product product;
    product.name = "Test Product";
    product.salePrice = 10.0;
    
    QString error;
    ASSERT_TRUE(service.createProduct(product, error));
    ASSERT_GT(product.id, 0);
}
```

### Integration Tests

```cpp
TEST_F(SalesIntegrationTest, CompleteSale_UpdatesStock) {
    // Setup
    ProductService productSvc;
    SalesService salesSvc;
    
    Product product = createTestProduct(10.0);  // stock inicial
    Sale sale = createTestSale(product, 2.0);   // vender 2
    
    // Act
    salesSvc.createSale(sale, error);
    
    // Assert
    auto updated = productSvc.getProduct(product.id);
    ASSERT_EQ(updated->currentStock, 8.0);
}
```

## 📐 Convenciones de Código

### Naming Conventions

**Clases:**
```cpp
PascalCase: ProductService, DatabaseManager
```

**Métodos:**
```cpp
camelCase: createProduct(), findById()
```

**Variables privadas:**
```cpp
m_prefix: m_database, m_productRepo
```

**Señales Qt:**
```cpp
past tense: productCreated, errorOccurred
```

**Propiedades Qt:**
```cpp
noun: count, isLoading, todaySales
```

### Organización de Archivos

**Header (.h):**
```cpp
// 1. Includes del sistema
#include <QObject>

// 2. Includes de Qt
#include <QSqlDatabase>

// 3. Includes del proyecto
#include "../models/Product.h"

// 4. Forward declarations
class QSqlQuery;

// 5. Clase
class ProductRepository { ... };
```

**Source (.cpp):**
```cpp
// 1. Include del header correspondiente
#include "ProductRepository.h"

// 2. Otros includes
#include <QSqlQuery>

// 3. Implementación
```

## 🔐 Seguridad

### SQL Injection Prevention

**MAL ❌:**
```cpp
QString sql = "SELECT * FROM products WHERE name = '" + name + "'";
```

**BIEN ✅:**
```cpp
QSqlQuery query;
query.prepare("SELECT * FROM products WHERE name = :name");
query.bindValue(":name", name);
```

### Validación de Datos

```cpp
bool ProductService::validateProduct(const Product& p, QString& error) {
    if (p.name.trimmed().isEmpty()) {
        error = "Nombre requerido";
        return false;
    }
    
    if (p.salePrice < 0) {
        error = "Precio inválido";
        return false;
    }
    
    // Validar unicidad
    if (!isSkuUnique(p.sku, p.id)) {
        error = "SKU duplicado";
        return false;
    }
    
    return true;
}
```

## 🚀 Deployment

### Crear Ejecutable Portable

```bash
# 1. Compilar en Release
cmake --build . --config Release

# 2. Copiar DLLs de Qt
windeployqt --qmldir ../qml appSistemaInventario.exe

# 3. Resultado: carpeta con .exe + DLLs
```

### Crear Instalador con Qt Installer Framework

```bash
# 1. Crear paquete
binarycreator -c config.xml -p packages Installer.exe

# 2. Distribuir Installer.exe
```

## 📚 Recursos Adicionales

### Documentación Qt
- [Qt SQL Module](https://doc.qt.io/qt-6/qtsql-index.html)
- [Qt QML](https://doc.qt.io/qt-6/qtqml-index.html)
- [Material Style](https://doc.qt.io/qt-6/qtquickcontrols-material.html)

### Mejores Prácticas Qt
- [Qt Coding Conventions](https://wiki.qt.io/Qt_Coding_Style)
- [QML Performance](https://doc.qt.io/qt-6/qtquick-performance.html)

### Patrones de Diseño
- "Design Patterns" - Gang of Four
- "Clean Architecture" - Robert C. Martin
- "Domain-Driven Design" - Eric Evans

---

**Esta arquitectura está diseñada para escalar y mantenerse fácilmente. 🎯**
