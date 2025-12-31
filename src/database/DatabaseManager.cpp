#include "DatabaseManager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDir>
#include <QStandardPaths>
#include <QDebug>

DatabaseManager::DatabaseManager(QObject *parent)
    : QObject(parent)
    , m_initialized(false)
{
}

DatabaseManager::~DatabaseManager()
{
    if (m_database.isOpen()) {
        m_database.close();
    }
}

DatabaseManager& DatabaseManager::instance()
{
    static DatabaseManager instance;
    return instance;
}

bool DatabaseManager::initialize(const QString& dbPath)
{
    QMutexLocker locker(&m_mutex);

    if (m_initialized) {
        return true;
    }

    // Determinar ruta de la base de datos
    QString databasePath = dbPath;
    if (databasePath.isEmpty()) {
        QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        QDir dir(dataDir);
        if (!dir.exists()) {
            dir.mkpath(".");
        }
        databasePath = dataDir + "/inventory.db";
    }

    qDebug() << "Inicializando base de datos en:" << databasePath;

    // Crear conexión SQLite
    m_database = QSqlDatabase::addDatabase("QSQLITE");
    m_database.setDatabaseName(databasePath);

    if (!m_database.open()) {
        m_lastError = m_database.lastError().text();
        qCritical() << "Error abriendo base de datos:" << m_lastError;
        emit databaseError(m_lastError);
        return false;
    }

    // Habilitar foreign keys en SQLite
    QSqlQuery query(m_database);
    query.exec("PRAGMA foreign_keys = ON");

    // Ejecutar migraciones
    if (!runMigrations()) {
        m_lastError = "Error ejecutando migraciones";
        qCritical() << m_lastError;
        emit databaseError(m_lastError);
        return false;
    }

    m_initialized = true;
    emit databaseReady();
    qDebug() << "Base de datos inicializada correctamente";

    return true;
}

QSqlDatabase& DatabaseManager::database()
{
    return m_database;
}

bool DatabaseManager::beginTransaction()
{
    QMutexLocker locker(&m_mutex);
    return m_database.transaction();
}

bool DatabaseManager::commit()
{
    QMutexLocker locker(&m_mutex);
    return m_database.commit();
}

bool DatabaseManager::rollback()
{
    QMutexLocker locker(&m_mutex);
    return m_database.rollback();
}

bool DatabaseManager::isConnected() const
{
    return m_database.isOpen();
}

QString DatabaseManager::lastError() const
{
    return m_lastError;
}

int DatabaseManager::getCurrentSchemaVersion()
{
    QSqlQuery query(m_database);
    query.prepare("SELECT version FROM schema_version ORDER BY version DESC LIMIT 1");
    
    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }
    return 0;
}

bool DatabaseManager::setSchemaVersion(int version)
{
    QSqlQuery query(m_database);
    query.prepare("INSERT INTO schema_version (version, applied_at) VALUES (?, datetime('now'))");
    query.addBindValue(version);
    return query.exec();
}

bool DatabaseManager::runMigrations()
{
    // Crear tabla de versiones si no existe
    QSqlQuery query(m_database);
    if (!query.exec("CREATE TABLE IF NOT EXISTS schema_version ("
                   "version INTEGER PRIMARY KEY,"
                   "applied_at TEXT NOT NULL)")) {
        m_lastError = query.lastError().text();
        return false;
    }

    int currentVersion = getCurrentSchemaVersion();
    qDebug() << "Versión actual del esquema:" << currentVersion;

    // Migración 1: Crear tablas iniciales
    if (currentVersion < 1) {
        qDebug() << "Aplicando migración 1: Tablas iniciales";
        if (!createTables()) {
            return false;
        }
        if (!insertSampleData()) {
            qWarning() << "Error insertando datos de ejemplo (no crítico)";
        }
        setSchemaVersion(1);
    }

    // Aquí se pueden agregar más migraciones en el futuro
    // if (currentVersion < 2) { ... }

    return true;
}

bool DatabaseManager::createTables()
{
    QSqlQuery query(m_database);

    // Tabla de categorías
    if (!query.exec(
        "CREATE TABLE IF NOT EXISTS categories ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "name TEXT NOT NULL UNIQUE,"
        "description TEXT,"
        "created_at TEXT DEFAULT (datetime('now')),"
        "updated_at TEXT DEFAULT (datetime('now'))"
        ")")) {
        m_lastError = query.lastError().text();
        qCritical() << "Error creando tabla categories:" << m_lastError;
        return false;
    }

    // Tabla de productos
    if (!query.exec(
        "CREATE TABLE IF NOT EXISTS products ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "name TEXT NOT NULL,"
        "sku TEXT UNIQUE,"
        "barcode TEXT UNIQUE,"
        "category_id INTEGER,"
        "current_stock REAL DEFAULT 0,"
        "minimum_stock REAL DEFAULT 0,"
        "purchase_price REAL DEFAULT 0,"
        "sale_price REAL DEFAULT 0,"
        "description TEXT,"
        "image_path TEXT,"
        "active INTEGER DEFAULT 1,"
        "created_at TEXT DEFAULT (datetime('now')),"
        "updated_at TEXT DEFAULT (datetime('now')),"
        "FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL"
        ")")) {
        m_lastError = query.lastError().text();
        qCritical() << "Error creando tabla products:" << m_lastError;
        return false;
    }

    // Tabla de tipos de movimiento
    if (!query.exec(
        "CREATE TABLE IF NOT EXISTS movement_types ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "code TEXT NOT NULL UNIQUE,"  // 'ENTRADA', 'SALIDA', 'AJUSTE'
        "name TEXT NOT NULL,"
        "affects_stock INTEGER NOT NULL"  // 1: incrementa, -1: decrementa, 0: ajuste
        ")")) {
        m_lastError = query.lastError().text();
        return false;
    }

    // Insertar tipos de movimiento predefinidos
    query.exec("INSERT OR IGNORE INTO movement_types (code, name, affects_stock) VALUES "
              "('COMPRA', 'Compra', 1), "
              "('VENTA', 'Venta', -1), "
              "('AJUSTE_POSITIVO', 'Ajuste Positivo', 1), "
              "('AJUSTE_NEGATIVO', 'Ajuste Negativo', -1), "
              "('DEVOLUCION_COMPRA', 'Devolución de Compra', -1), "
              "('DEVOLUCION_VENTA', 'Devolución de Venta', 1)");

    // Tabla de movimientos de stock (Kardex)
    if (!query.exec(
        "CREATE TABLE IF NOT EXISTS stock_movements ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "product_id INTEGER NOT NULL,"
        "movement_type_id INTEGER NOT NULL,"
        "quantity REAL NOT NULL,"
        "previous_stock REAL NOT NULL,"
        "new_stock REAL NOT NULL,"
        "unit_price REAL,"
        "reference TEXT,"  // Referencia a venta, compra, etc.
        "notes TEXT,"
        "created_at TEXT DEFAULT (datetime('now')),"
        "created_by TEXT,"
        "FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,"
        "FOREIGN KEY (movement_type_id) REFERENCES movement_types(id)"
        ")")) {
        m_lastError = query.lastError().text();
        return false;
    }

    // Tabla de clientes
    if (!query.exec(
        "CREATE TABLE IF NOT EXISTS customers ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "name TEXT NOT NULL,"
        "document_type TEXT,"  // DNI, RUC, etc.
        "document_number TEXT UNIQUE,"
        "email TEXT,"
        "phone TEXT,"
        "address TEXT,"
        "created_at TEXT DEFAULT (datetime('now')),"
        "updated_at TEXT DEFAULT (datetime('now'))"
        ")")) {
        m_lastError = query.lastError().text();
        return false;
    }

    // Tabla de métodos de pago
    if (!query.exec(
        "CREATE TABLE IF NOT EXISTS payment_methods ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "code TEXT NOT NULL UNIQUE,"
        "name TEXT NOT NULL,"
        "active INTEGER DEFAULT 1"
        ")")) {
        m_lastError = query.lastError().text();
        return false;
    }

    // Insertar métodos de pago predefinidos
    query.exec("INSERT OR IGNORE INTO payment_methods (code, name) VALUES "
              "('EFECTIVO', 'Efectivo'), "
              "('TARJETA', 'Tarjeta de Crédito/Débito'), "
              "('TRANSFERENCIA', 'Transferencia Bancaria'), "
              "('YAPE', 'Yape'), "
              "('PLIN', 'Plin')");

    // Tabla de ventas
    if (!query.exec(
        "CREATE TABLE IF NOT EXISTS sales ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "invoice_number TEXT UNIQUE NOT NULL,"
        "customer_id INTEGER,"
        "subtotal REAL NOT NULL,"
        "tax REAL DEFAULT 0,"
        "discount REAL DEFAULT 0,"
        "total REAL NOT NULL,"
        "payment_method_id INTEGER,"
        "status TEXT DEFAULT 'COMPLETED',"  // COMPLETED, CANCELLED, PENDING
        "notes TEXT,"
        "created_at TEXT DEFAULT (datetime('now')),"
        "created_by TEXT,"
        "FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,"
        "FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id)"
        ")")) {
        m_lastError = query.lastError().text();
        return false;
    }

    // Tabla de items de venta
    if (!query.exec(
        "CREATE TABLE IF NOT EXISTS sale_items ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "sale_id INTEGER NOT NULL,"
        "product_id INTEGER NOT NULL,"
        "product_name TEXT NOT NULL,"  // Snapshot del nombre al momento de la venta
        "quantity REAL NOT NULL,"
        "unit_price REAL NOT NULL,"
        "subtotal REAL NOT NULL,"
        "FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,"
        "FOREIGN KEY (product_id) REFERENCES products(id)"
        ")")) {
        m_lastError = query.lastError().text();
        return false;
    }

    // Tabla de configuración
    if (!query.exec(
        "CREATE TABLE IF NOT EXISTS settings ("
        "key TEXT PRIMARY KEY,"
        "value TEXT,"
        "updated_at TEXT DEFAULT (datetime('now'))"
        ")")) {
        m_lastError = query.lastError().text();
        return false;
    }

    // Tabla de plantillas de importación Excel
    if (!query.exec(
        "CREATE TABLE IF NOT EXISTS import_templates ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "name TEXT NOT NULL UNIQUE,"
        "column_mapping TEXT NOT NULL,"  // JSON con mapeo de columnas
        "created_at TEXT DEFAULT (datetime('now')),"
        "updated_at TEXT DEFAULT (datetime('now'))"
        ")")) {
        m_lastError = query.lastError().text();
        return false;
    }

    // Índices para mejorar rendimiento
    query.exec("CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_stock_movements_product ON stock_movements(product_id)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_stock_movements_date ON stock_movements(created_at)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_sales_invoice ON sales(invoice_number)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(created_at)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id)");

    qDebug() << "Todas las tablas creadas correctamente";
    return true;
}

bool DatabaseManager::insertSampleData()
{
    qDebug() << "Insertando datos de ejemplo...";
    
    QSqlQuery query(m_database);
    
    // Verificar si ya hay productos
    query.exec("SELECT COUNT(*) FROM products");
    if (query.next() && query.value(0).toInt() > 0) {
        qDebug() << "Ya existen productos en la base de datos, omitiendo datos de ejemplo";
        return true;
    }
    
    // Insertar categorías
    query.exec("INSERT INTO categories (name, description) VALUES ('Electrónica', 'Dispositivos electrónicos')");
    query.exec("INSERT INTO categories (name, description) VALUES ('Oficina', 'Artículos de oficina')");
    query.exec("INSERT INTO categories (name, description) VALUES ('Útiles', 'Útiles escolares')");
    
    // Insertar métodos de pago
    query.exec("INSERT INTO payment_methods (name, is_active) VALUES ('Efectivo', 1)");
    query.exec("INSERT INTO payment_methods (name, is_active) VALUES ('Tarjeta', 1)");
    query.exec("INSERT INTO payment_methods (name, is_active) VALUES ('Transferencia', 1)");
    
    // Insertar productos de ejemplo
    struct Product {
        QString name;
        QString sku;
        QString barcode;
        int categoryId;
        double purchasePrice;
        double salePrice;
        int currentStock;
        int minimumStock;
    };
    
    QList<Product> products = {
        {"Laptop Dell Inspiron", "LAP-001", "7501234567890", 1, 2500.00, 3200.00, 15, 5},
        {"Mouse Logitech", "MOU-001", "7501234567891", 1, 25.00, 45.00, 50, 10},
        {"Teclado Mecánico", "TEC-001", "7501234567892", 1, 80.00, 120.00, 30, 8},
        {"Monitor 24\"", "MON-001", "7501234567893", 1, 450.00, 650.00, 20, 5},
        {"USB 32GB", "USB-001", "7501234567894", 1, 15.00, 28.00, 100, 20},
        {"Papel Bond A4 x500", "PAP-001", "7501234567895", 2, 12.00, 18.00, 200, 50},
        {"Lapiceros Caja x50", "LAP-002", "7501234567896", 2, 20.00, 35.00, 80, 15},
        {"Folder Manila x100", "FOL-001", "7501234567897", 2, 25.00, 40.00, 150, 30},
        {"Archivador A-Z", "ARC-001", "7501234567898", 2, 8.00, 15.00, 60, 15},
        {"Engrapador Grande", "ENG-001", "7501234567899", 2, 15.00, 25.00, 40, 10},
        {"Cuaderno 100 hojas", "CUA-001", "7501234567900", 3, 3.50, 6.00, 200, 50},
        {"Papel Crepé x10 unidades", "CRE-001", "7501234567901", 3, 8.00, 15.00, 120, 30},
        {"Tijera Escolar", "TIJ-001", "7501234567902", 3, 5.00, 10.00, 80, 20},
        {"Goma en Barra", "GOM-001", "7501234567903", 3, 2.50, 5.00, 150, 40},
        {"Colores x12", "COL-001", "7501234567904", 3, 8.00, 14.00, 100, 25}
    };
    
    query.prepare("INSERT INTO products (name, sku, barcode, category_id, purchase_price, sale_price, "
                 "current_stock, minimum_stock, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)");
    
    for (const auto& product : products) {
        query.addBindValue(product.name);
        query.addBindValue(product.sku);
        query.addBindValue(product.barcode);
        query.addBindValue(product.categoryId);
        query.addBindValue(product.purchasePrice);
        query.addBindValue(product.salePrice);
        query.addBindValue(product.currentStock);
        query.addBindValue(product.minimumStock);
        
        if (!query.exec()) {
            qWarning() << "Error insertando producto" << product.name << ":" << query.lastError().text();
        }
    }
    
    qDebug() << "Datos de ejemplo insertados correctamente";
    return true;
}
