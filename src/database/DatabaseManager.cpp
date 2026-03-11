#include "DatabaseManager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDir>
#include <QStandardPaths>
#include <QDebug>
#include <QFile>
#include <QDateTime>

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

    qDebug() << "=== DatabaseManager::initialize() INICIADO ===";

    if (m_initialized) {
        qDebug() << "Base de datos ya inicializada";
        return true;
    }

    // Determinar ruta de la base de datos
    QString databasePath = dbPath;
    if (databasePath.isEmpty()) {
        QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        QDir dir(dataDir);
        if (!dir.exists()) {
            qDebug() << "Creando directorio de datos:" << dataDir;
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
    
    qDebug() << "Base de datos abierta correctamente";

    // Habilitar foreign keys en SQLite
    QSqlQuery query(m_database);
    if (!query.exec("PRAGMA foreign_keys = ON")) {
        qWarning() << "Error habilitando foreign keys:" << query.lastError().text();
    } else {
        qDebug() << "Foreign keys habilitadas";
    }

    // Ejecutar migraciones
    qDebug() << "Llamando a runMigrations()...";
    if (!runMigrations()) {
        m_lastError = "Error ejecutando migraciones";
        qCritical() << m_lastError;
        emit databaseError(m_lastError);
        return false;
    }

    m_initialized = true;
    emit databaseReady();
    qDebug() << "=== Base de datos inicializada correctamente ===";

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
    qDebug() << "=== INICIANDO MIGRACIONES ===";
    
    // Crear tabla de versiones si no existe
    QSqlQuery query(m_database);
    if (!query.exec("CREATE TABLE IF NOT EXISTS schema_version ("
                   "version INTEGER PRIMARY KEY,"
                   "applied_at TEXT NOT NULL)")) {
        m_lastError = query.lastError().text();
        qCritical() << "Error creando tabla schema_version:" << m_lastError;
        return false;
    }

    int currentVersion = getCurrentSchemaVersion();
    qDebug() << "Versión actual del esquema:" << currentVersion;

    // Migración 1: Crear tablas iniciales
    if (currentVersion < 1) {
        qDebug() << "Aplicando migración 1: Tablas iniciales";
        if (!createTables()) {
            qCritical() << "Error en createTables()";
            return false;
        }
        if (!insertSampleData()) {
            qWarning() << "Error insertando datos de ejemplo (no crítico)";
        }
        if (!setSchemaVersion(1)) {
            qCritical() << "Error estableciendo versión de esquema";
            return false;
        }
        qDebug() << "Migración 1 completada exitosamente";
    }
    
    // Migración 2: Agregar tabla de usuarios (si no existe)
    if (currentVersion < 3) {
        qDebug() << "Aplicando migración 2/3: Verificar y crear tabla users";
        
        // Verificar si la tabla users existe
        bool usersTableExists = query.exec("SELECT name FROM sqlite_master WHERE type='table' AND name='users'") && query.next();
        
        if (!usersTableExists) {
            qDebug() << "Tabla users no existe, creándola...";
            
            if (!query.exec(
                "CREATE TABLE IF NOT EXISTS users ("
                "id INTEGER PRIMARY KEY AUTOINCREMENT,"
                "username TEXT NOT NULL UNIQUE,"
                "password TEXT NOT NULL,"
                "full_name TEXT NOT NULL,"
                "role TEXT NOT NULL,"
                "is_active INTEGER DEFAULT 1,"
                "created_at TEXT DEFAULT (datetime('now')),"
                "last_login TEXT"
                ")")) {
                m_lastError = query.lastError().text();
                qCritical() << "Error creando tabla users:" << m_lastError;
                return false;
            }
            qDebug() << "Tabla users creada exitosamente";
            
            // Insertar usuarios por defecto
            qDebug() << "Insertando usuarios por defecto...";
            if (!query.exec(
                "INSERT OR IGNORE INTO users (username, password, full_name, role, is_active) VALUES "
                "('admin', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'Administrador del Sistema', 'Admin', 1), "
                "('vendedor', '56976bf24998ca63e35fe4f1e2469b5751d1856003e8d16fef0aafef496ed044', 'Vendedor Principal', 'Vendedor', 1), "
                "('dev', '87274af01876341455b32d805946f272871bb42effa6604dccf28bb027afa82b', 'Desarrollador', 'Programador', 1)"
            )) {
                qWarning() << "Error insertando usuarios por defecto:" << query.lastError().text();
            } else {
                qDebug() << "Usuarios insertados. Filas afectadas:" << query.numRowsAffected();
            }
        } else {
            qDebug() << "Tabla users ya existe";
        }
        
        if (!setSchemaVersion(3)) {
            qCritical() << "Error estableciendo versión de esquema";
            return false;
        }
        qDebug() << "Migración 2/3 completada exitosamente";
    } else {
        qDebug() << "Base de datos ya está actualizada (versión" << currentVersion << ")";
    }
    
    // Migración 4: Crear tabla de categorías y agregar category_name a products
    if (currentVersion < 4) {
        qDebug() << "Aplicando migración 4: Tabla de categorías";
        
        // Crear tabla de categorías
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
        qDebug() << "Tabla categories creada";
        
        // Insertar categorías predefinidas
        query.exec(
            "INSERT OR IGNORE INTO categories (name, description) VALUES "
            "('Alimentos y Bebidas', 'Productos alimenticios y bebidas'), "
            "('Lácteos', 'Productos lácteos'), "
            "('Carnes y Embutidos', 'Carnes, embutidos y derivados'), "
            "('Frutas y Verduras', 'Productos frescos'), "
            "('Panadería y Pastelería', 'Pan, pasteles y productos de panadería'), "
            "('Snacks y Golosinas', 'Snacks, dulces y golosinas'), "
            "('Bebidas', 'Bebidas de todo tipo'), "
            "('Productos de Limpieza', 'Artículos de limpieza y hogar'), "
            "('Cuidado Personal', 'Productos de higiene personal'), "
            "('Hogar y Decoración', 'Artículos para el hogar'), "
            "('Electrónica', 'Dispositivos electrónicos'), "
            "('Papelería y Oficina', 'Artículos de oficina y papelería'), "
            "('Juguetes y Entretenimiento', 'Juguetes y entretenimiento'), "
            "('Mascotas', 'Productos para mascotas'), "
            "('Ferretería', 'Herramientas y ferretería'), "
            "('Otros', 'Otros productos')"
        );
        
        if (!setSchemaVersion(4)) {
            qCritical() << "Error estableciendo versión de esquema 4";
            return false;
        }
        qDebug() << "Migración 4 completada";
    }

    // Migración 5: Crear tabla de diseños de tickets
    if (currentVersion < 5) {
        qDebug() << "Aplicando migración 5: Tabla de diseños de tickets";
        
        if (!query.exec(
            "CREATE TABLE IF NOT EXISTS ticket_templates ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "name TEXT NOT NULL UNIQUE,"
            "layout_json TEXT NOT NULL,"
            "is_active INTEGER DEFAULT 0,"
            "created_at TEXT DEFAULT (datetime('now')),"
            "updated_at TEXT DEFAULT (datetime('now'))"
            ")")) {
            m_lastError = query.lastError().text();
            qCritical() << "Error creando tabla ticket_templates:" << m_lastError;
            return false;
        }
        qDebug() << "Tabla ticket_templates creada";
        
        if (!setSchemaVersion(5)) {
            qCritical() << "Error estableciendo versión de esquema 5";
            return false;
        }
        qDebug() << "Migración 5 completada";
    }

    // Migración 6: Agregar campos de estadísticas a customers
    if (currentVersion < 6) {
        qDebug() << "Aplicando migración 6: Campos de estadísticas en customers";
        
        // Verificar si las columnas ya existen
        query.exec("PRAGMA table_info(customers)");
        QStringList existingColumns;
        while (query.next()) {
            existingColumns << query.value(1).toString();
        }
        
        // Agregar total_purchases si no existe
        if (!existingColumns.contains("total_purchases")) {
            if (!query.exec("ALTER TABLE customers ADD COLUMN total_purchases INTEGER DEFAULT 0")) {
                qWarning() << "Error agregando total_purchases:" << query.lastError().text();
            } else {
                qDebug() << "Columna total_purchases agregada";
            }
        }
        
        // Agregar total_spent si no existe
        if (!existingColumns.contains("total_spent")) {
            if (!query.exec("ALTER TABLE customers ADD COLUMN total_spent REAL DEFAULT 0.0")) {
                qWarning() << "Error agregando total_spent:" << query.lastError().text();
            } else {
                qDebug() << "Columna total_spent agregada";
            }
        }
        
        // Agregar last_purchase_date si no existe
        if (!existingColumns.contains("last_purchase_date")) {
            if (!query.exec("ALTER TABLE customers ADD COLUMN last_purchase_date TEXT")) {
                qWarning() << "Error agregando last_purchase_date:" << query.lastError().text();
            } else {
                qDebug() << "Columna last_purchase_date agregada";
            }
        }
        
        // Calcular estadísticas iniciales desde las ventas existentes
        qDebug() << "Calculando estadísticas iniciales de clientes...";
        if (!query.exec(
            "UPDATE customers SET "
            "total_purchases = (SELECT COUNT(*) FROM sales WHERE sales.customer_id = customers.id AND sales.status = 'COMPLETED'), "
            "total_spent = COALESCE((SELECT SUM(total) FROM sales WHERE sales.customer_id = customers.id AND sales.status = 'COMPLETED'), 0), "
            "last_purchase_date = (SELECT MAX(created_at) FROM sales WHERE sales.customer_id = customers.id AND sales.status = 'COMPLETED')"
        )) {
            qWarning() << "Error calculando estadísticas iniciales:" << query.lastError().text();
        } else {
            qDebug() << "Estadísticas iniciales calculadas";
        }
        
        if (!setSchemaVersion(6)) {
            qCritical() << "Error estableciendo versión de esquema 6";
            return false;
        }
        qDebug() << "Migración 6 completada";
    }

    // Migración 7: Agregar campos de facturación a sales
    if (currentVersion < 7) {
        qDebug() << "Aplicando migración 7: Campos de facturación en sales";
        
        // Verificar si las columnas ya existen
        query.exec("PRAGMA table_info(sales)");
        QStringList existingColumns;
        while (query.next()) {
            existingColumns << query.value(1).toString();
        }
        
        // Agregar customer_name si no existe
        if (!existingColumns.contains("customer_name")) {
            if (!query.exec("ALTER TABLE sales ADD COLUMN customer_name TEXT")) {
                qWarning() << "Error agregando customer_name:" << query.lastError().text();
            } else {
                qDebug() << "Columna customer_name agregada";
            }
        }
        
        // Agregar customer_ruc si no existe
        if (!existingColumns.contains("customer_ruc")) {
            if (!query.exec("ALTER TABLE sales ADD COLUMN customer_ruc TEXT")) {
                qWarning() << "Error agregando customer_ruc:" << query.lastError().text();
            } else {
                qDebug() << "Columna customer_ruc agregada";
            }
        }
        
        // Agregar customer_business_name si no existe
        if (!existingColumns.contains("customer_business_name")) {
            if (!query.exec("ALTER TABLE sales ADD COLUMN customer_business_name TEXT")) {
                qWarning() << "Error agregando customer_business_name:" << query.lastError().text();
            } else {
                qDebug() << "Columna customer_business_name agregada";
            }
        }
        
        // Agregar customer_address si no existe
        if (!existingColumns.contains("customer_address")) {
            if (!query.exec("ALTER TABLE sales ADD COLUMN customer_address TEXT")) {
                qWarning() << "Error agregando customer_address:" << query.lastError().text();
            } else {
                qDebug() << "Columna customer_address agregada";
            }
        }
        
        if (!setSchemaVersion(7)) {
            qCritical() << "Error estableciendo versión de esquema 7";
            return false;
        }
        qDebug() << "Migración 7 completada";
    }

    // Migración 8: Sistema de créditos y deudas
    if (currentVersion < 8) {
        qDebug() << "Aplicando migración 8: Sistema de créditos y deudas";
        
        // Verificar columnas existentes en customers
        query.exec("PRAGMA table_info(customers)");
        QStringList customerColumns;
        while (query.next()) {
            customerColumns << query.value(1).toString();
        }
        
        // Agregar credit_limit si no existe
        if (!customerColumns.contains("credit_limit")) {
            if (!query.exec("ALTER TABLE customers ADD COLUMN credit_limit REAL DEFAULT 0")) {
                qWarning() << "Error agregando credit_limit:" << query.lastError().text();
            } else {
                qDebug() << "Columna credit_limit agregada";
            }
        }
        
        // Agregar current_debt si no existe
        if (!customerColumns.contains("current_debt")) {
            if (!query.exec("ALTER TABLE customers ADD COLUMN current_debt REAL DEFAULT 0")) {
                qWarning() << "Error agregando current_debt:" << query.lastError().text();
            } else {
                qDebug() << "Columna current_debt agregada";
            }
        }
        
        // Verificar columnas existentes en sales
        query.exec("PRAGMA table_info(sales)");
        QStringList salesColumns;
        while (query.next()) {
            salesColumns << query.value(1).toString();
        }
        
        // Agregar payment_type si no existe (CONTADO o CREDITO)
        if (!salesColumns.contains("payment_type")) {
            if (!query.exec("ALTER TABLE sales ADD COLUMN payment_type TEXT DEFAULT 'CONTADO'")) {
                qWarning() << "Error agregando payment_type:" << query.lastError().text();
            } else {
                qDebug() << "Columna payment_type agregada";
            }
        }
        
        // Agregar payment_status si no existe (PAID, PENDING, PARTIAL)
        if (!salesColumns.contains("payment_status")) {
            if (!query.exec("ALTER TABLE sales ADD COLUMN payment_status TEXT DEFAULT 'PAID'")) {
                qWarning() << "Error agregando payment_status:" << query.lastError().text();
            } else {
                qDebug() << "Columna payment_status agregada";
            }
        }
        
        // Actualizar ventas existentes: todas son al contado y pagadas
        if (!query.exec("UPDATE sales SET payment_type = 'CONTADO', payment_status = 'PAID' WHERE payment_type IS NULL OR payment_status IS NULL")) {
            qWarning() << "Error actualizando ventas existentes:" << query.lastError().text();
        } else {
            qDebug() << "Ventas existentes marcadas como CONTADO y PAID";
        }
        
        if (!setSchemaVersion(8)) {
            qCritical() << "Error estableciendo versión de esquema 8";
            return false;
        }
        qDebug() << "Migración 8 completada";
    }

    // Migración 9: Agregar campos de resumen de productos en ventas
    if (currentVersion < 9) {
        qDebug() << "Aplicando migración 9: Campos de resumen de productos";
        
        query.exec("PRAGMA table_info(sales)");
        QStringList salesColumns;
        while (query.next()) {
            salesColumns << query.value(1).toString();
        }
        
        // Agregar item_count si no existe (cantidad total de productos vendidos)
        if (!salesColumns.contains("item_count")) {
            if (!query.exec("ALTER TABLE sales ADD COLUMN item_count INTEGER DEFAULT 0")) {
                qWarning() << "Error agregando item_count:" << query.lastError().text();
            } else {
                qDebug() << "Columna item_count agregada";
            }
        }
        
        // Agregar product_names si no existe (lista de nombres de productos)
        if (!salesColumns.contains("product_names")) {
            if (!query.exec("ALTER TABLE sales ADD COLUMN product_names TEXT")) {
                qWarning() << "Error agregando product_names:" << query.lastError().text();
            } else {
                qDebug() << "Columna product_names agregada";
            }
        }
        
        // Actualizar ventas existentes con información de sus items
        qDebug() << "Actualizando ventas existentes con información de productos...";
        QSqlQuery selectSales(m_database);
        selectSales.exec("SELECT id FROM sales");
        
        while (selectSales.next()) {
            int saleId = selectSales.value(0).toInt();
            
            // Obtener items de esta venta
            QSqlQuery selectItems(m_database);
            selectItems.prepare("SELECT product_name, quantity FROM sale_items WHERE sale_id = :sale_id");
            selectItems.bindValue(":sale_id", saleId);
            
            if (selectItems.exec()) {
                int totalItems = 0;
                QStringList productNames;
                
                while (selectItems.next()) {
                    QString productName = selectItems.value(0).toString();
                    double quantity = selectItems.value(1).toDouble();
                    totalItems += static_cast<int>(quantity);
                    
                    if (!productNames.contains(productName)) {
                        productNames << productName;
                    }
                }
                
                // Actualizar la venta con esta información
                QSqlQuery updateSale(m_database);
                updateSale.prepare("UPDATE sales SET item_count = :item_count, product_names = :product_names WHERE id = :sale_id");
                updateSale.bindValue(":item_count", totalItems);
                updateSale.bindValue(":product_names", productNames.join(", "));
                updateSale.bindValue(":sale_id", saleId);
                
                if (!updateSale.exec()) {
                    qWarning() << "Error actualizando venta" << saleId << ":" << updateSale.lastError().text();
                }
            }
        }
        
        qDebug() << "Ventas existentes actualizadas con información de productos";
        
        if (!setSchemaVersion(9)) {
            qCritical() << "Error estableciendo versión de esquema 9";
            return false;
        }
        qDebug() << "Migración 9 completada";
    }

    if (currentVersion < 10) {
        qDebug() << "Aplicando migración 10: Campos de pago y vuelto";
        
        query.exec("PRAGMA table_info(sales)");
        QStringList salesColumns;
        while (query.next()) {
            salesColumns << query.value(1).toString();
        }
        
        // Agregar amount_paid si no existe (monto con el que pagó el cliente)
        if (!salesColumns.contains("amount_paid")) {
            if (!query.exec("ALTER TABLE sales ADD COLUMN amount_paid REAL DEFAULT 0")) {
                qWarning() << "Error agregando amount_paid:" << query.lastError().text();
            } else {
                qDebug() << "Columna amount_paid agregada";
            }
        }
        
        // Agregar change_given si no existe (vuelto dado al cliente)
        if (!salesColumns.contains("change_given")) {
            if (!query.exec("ALTER TABLE sales ADD COLUMN change_given REAL DEFAULT 0")) {
                qWarning() << "Error agregando change_given:" << query.lastError().text();
            } else {
                qDebug() << "Columna change_given agregada";
            }
        }
        
        // Actualizar ventas existentes: amount_paid = total (sin vuelto registrado)
        qDebug() << "Actualizando ventas existentes con valores por defecto...";
        if (!query.exec("UPDATE sales SET amount_paid = total, change_given = 0 WHERE amount_paid = 0")) {
            qWarning() << "Error actualizando ventas existentes:" << query.lastError().text();
        } else {
            qDebug() << "Ventas existentes actualizadas";
        }
        
        if (!setSchemaVersion(10)) {
            qCritical() << "Error estableciendo versión de esquema 10";
            return false;
        }
        qDebug() << "Migración 10 completada";
    }
    
    // Migración 11: Sistema de permisos personalizados y rastreo de usuario en ventas
    if (currentVersion < 11) {
        qDebug() << "Aplicando migración 11: Permisos personalizados y user_id en ventas";
        
        // Verificar columnas existentes en users
        query.exec("PRAGMA table_info(users)");
        QStringList userColumns;
        while (query.next()) {
            userColumns << query.value(1).toString();
        }
        
        // Agregar email si no existe
        if (!userColumns.contains("email")) {
            if (!query.exec("ALTER TABLE users ADD COLUMN email TEXT")) {
                qWarning() << "Error agregando email:" << query.lastError().text();
            } else {
                qDebug() << "Columna email agregada a users";
            }
        }
        
        // Agregar custom_permissions si no existe (JSON con permisos personalizados)
        if (!userColumns.contains("custom_permissions")) {
            if (!query.exec("ALTER TABLE users ADD COLUMN custom_permissions TEXT")) {
                qWarning() << "Error agregando custom_permissions:" << query.lastError().text();
            } else {
                qDebug() << "Columna custom_permissions agregada a users";
            }
        }
        
        // Verificar columnas existentes en sales
        query.exec("PRAGMA table_info(sales)");
        QStringList salesColumns;
        while (query.next()) {
            salesColumns << query.value(1).toString();
        }
        
        // Agregar user_id si no existe (quién realizó la venta)
        if (!salesColumns.contains("user_id")) {
            if (!query.exec("ALTER TABLE sales ADD COLUMN user_id INTEGER")) {
                qWarning() << "Error agregando user_id:" << query.lastError().text();
            } else {
                qDebug() << "Columna user_id agregada a sales";
                
                // Intentar asignar ventas antiguas al admin (id=1) si existe
                query.exec("UPDATE sales SET user_id = 1 WHERE user_id IS NULL AND EXISTS(SELECT 1 FROM users WHERE id = 1)");
            }
        }
        
        if (!setSchemaVersion(11)) {
            qCritical() << "Error estableciendo versión de esquema 11";
            return false;
        }
        qDebug() << "Migración 11 completada";
    }

    qDebug() << "=== MIGRACIONES COMPLETADAS ===";
    return true;
}

bool DatabaseManager::createTables()
{
    QSqlQuery query(m_database);

    qDebug() << "=== CREANDO TABLAS ===";
    
    // Tabla de usuarios (NUEVA - debe ser la primera)
    qDebug() << "Creando tabla users...";
    if (!query.exec(
        "CREATE TABLE IF NOT EXISTS users ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "username TEXT NOT NULL UNIQUE,"
        "password TEXT NOT NULL,"  // Almacenado con hash SHA-256
        "full_name TEXT NOT NULL,"
        "email TEXT,"
        "role TEXT NOT NULL,"  // 'Admin', 'Vendedor', 'Programador', 'Custom'
        "custom_permissions TEXT,"  // JSON con permisos cuando role='Custom'
        "is_active INTEGER DEFAULT 1,"
        "created_at TEXT DEFAULT (datetime('now')),"
        "last_login TEXT"
        ")")) {
        m_lastError = query.lastError().text();
        qCritical() << "Error creando tabla users:" << m_lastError;
        return false;
    }
    qDebug() << "Tabla users creada exitosamente";

    // Insertar usuarios por defecto (solo si no existen)
    // Contraseñas: admin123, vendedor123, dev123
    qDebug() << "Insertando usuarios por defecto...";
    if (!query.exec(
        "INSERT OR IGNORE INTO users (username, password, full_name, role, is_active) VALUES "
        "('admin', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'Administrador del Sistema', 'Admin', 1), "
        "('vendedor', '56976bf24998ca63e35fe4f1e2469b5751d1856003e8d16fef0aafef496ed044', 'Vendedor Principal', 'Vendedor', 1), "
        "('dev', '87274af01876341455b32d805946f272871bb42effa6604dccf28bb027afa82b', 'Desarrollador', 'Programador', 1)"
    )) {
        qWarning() << "Error insertando usuarios por defecto:" << query.lastError().text();
    } else {
        qDebug() << "Usuarios insertados. Filas afectadas:" << query.numRowsAffected();
    }
    
    // Verificar usuarios insertados
    if (query.exec("SELECT COUNT(*) FROM users")) {
        if (query.next()) {
            qDebug() << "Total usuarios en BD después de insertar:" << query.value(0).toInt();
        }
    }

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
        "voucher_type TEXT DEFAULT 'TICKET',"  // BOLETA, FACTURA, TICKET
        "customer_id INTEGER,"
        "user_id INTEGER,"  // Usuario que realizó la venta
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
        "FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,"
        "FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id)"
        ")")) {
        m_lastError = query.lastError().text();
        return false;
    }
    
    // Migración: Agregar voucher_type si no existe
    query.exec("PRAGMA table_info(sales)");
    bool hasVoucherType = false;
    while (query.next()) {
        if (query.value(1).toString() == "voucher_type") {
            hasVoucherType = true;
            break;
        }
    }
    if (!hasVoucherType) {
        if (!query.exec("ALTER TABLE sales ADD COLUMN voucher_type TEXT DEFAULT 'TICKET'")) {
            qWarning() << "No se pudo agregar voucher_type (probablemente ya existe):" << query.lastError().text();
        }
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

    // Tabla de diseños de tickets
    if (!query.exec(
        "CREATE TABLE IF NOT EXISTS ticket_templates ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "name TEXT NOT NULL UNIQUE,"
        "layout_json TEXT NOT NULL,"  // JSON con diseño del ticket
        "is_active INTEGER DEFAULT 0,"  // 1 = activo, 0 = inactivo
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

bool DatabaseManager::exportDatabase(const QString& destinationPath)
{
    QMutexLocker locker(&m_mutex);
    
    if (!m_database.isOpen()) {
        m_lastError = "Base de datos no está abierta";
        qWarning() << m_lastError;
        return false;
    }
    
    QString sourcePath = m_database.databaseName();
    
    // Crear directorio si no existe
    QFileInfo destInfo(destinationPath);
    QDir destDir = destInfo.absoluteDir();
    if (!destDir.exists()) {
        if (!destDir.mkpath(".")) {
            m_lastError = "No se pudo crear el directorio de destino";
            qWarning() << m_lastError;
            return false;
        }
    }
    
    // Si el archivo de destino existe, eliminarlo
    if (QFile::exists(destinationPath)) {
        if (!QFile::remove(destinationPath)) {
            m_lastError = "No se pudo eliminar el archivo de destino existente";
            qWarning() << m_lastError;
            return false;
        }
    }
    
    // Copiar archivo de base de datos
    if (!QFile::copy(sourcePath, destinationPath)) {
        m_lastError = "Error al copiar la base de datos";
        qWarning() << m_lastError;
        return false;
    }
    
    qDebug() << "Base de datos exportada exitosamente a:" << destinationPath;
    return true;
}

QString DatabaseManager::getDatabasePath() const
{
    return m_database.databaseName();
}
