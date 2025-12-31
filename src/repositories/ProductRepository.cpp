#include "ProductRepository.h"
#include "../database/DatabaseManager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDebug>

int ProductRepository::create(Product& product)
{
    QSqlQuery query(DatabaseManager::instance().database());
    
    query.prepare(
        "INSERT INTO products (name, sku, barcode, category_id, current_stock, "
        "minimum_stock, purchase_price, sale_price, description, image_path, active) "
        "VALUES (:name, :sku, :barcode, :category_id, :current_stock, "
        ":minimum_stock, :purchase_price, :sale_price, :description, :image_path, :active)"
    );

    query.bindValue(":name", product.name);
    query.bindValue(":sku", product.sku.isEmpty() ? QVariant() : product.sku);
    query.bindValue(":barcode", product.barcode.isEmpty() ? QVariant() : product.barcode);
    query.bindValue(":category_id", product.categoryId > 0 ? product.categoryId : QVariant());
    query.bindValue(":current_stock", product.currentStock);
    query.bindValue(":minimum_stock", product.minimumStock);
    query.bindValue(":purchase_price", product.purchasePrice);
    query.bindValue(":sale_price", product.salePrice);
    query.bindValue(":description", product.description);
    query.bindValue(":image_path", product.imagePath);
    query.bindValue(":active", product.active);

    if (!query.exec()) {
        qCritical() << "Error creando producto:" << query.lastError().text();
        return 0;
    }

    int newId = query.lastInsertId().toInt();
    product.id = newId;
    return newId;
}

bool ProductRepository::update(const Product& product)
{
    QSqlQuery query(DatabaseManager::instance().database());
    
    query.prepare(
        "UPDATE products SET name = :name, sku = :sku, barcode = :barcode, "
        "category_id = :category_id, minimum_stock = :minimum_stock, "
        "purchase_price = :purchase_price, sale_price = :sale_price, "
        "description = :description, image_path = :image_path, active = :active, "
        "updated_at = datetime('now') WHERE id = :id"
    );

    query.bindValue(":id", product.id);
    query.bindValue(":name", product.name);
    query.bindValue(":sku", product.sku.isEmpty() ? QVariant() : product.sku);
    query.bindValue(":barcode", product.barcode.isEmpty() ? QVariant() : product.barcode);
    query.bindValue(":category_id", product.categoryId > 0 ? product.categoryId : QVariant());
    query.bindValue(":minimum_stock", product.minimumStock);
    query.bindValue(":purchase_price", product.purchasePrice);
    query.bindValue(":sale_price", product.salePrice);
    query.bindValue(":description", product.description);
    query.bindValue(":image_path", product.imagePath);
    query.bindValue(":active", product.active);

    if (!query.exec()) {
        qCritical() << "Error actualizando producto:" << query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}

bool ProductRepository::remove(int id)
{
    // Soft delete: marcar como inactivo
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare("UPDATE products SET active = 0 WHERE id = :id");
    query.bindValue(":id", id);
    
    if (!query.exec()) {
        qCritical() << "Error eliminando producto:" << query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}

std::optional<Product> ProductRepository::findById(int id)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare(
        "SELECT p.*, c.name as category_name "
        "FROM products p "
        "LEFT JOIN categories c ON p.category_id = c.id "
        "WHERE p.id = :id"
    );
    query.bindValue(":id", id);

    if (!query.exec()) {
        qCritical() << "Error buscando producto por ID:" << query.lastError().text();
        return std::nullopt;
    }

    if (query.next()) {
        return mapFromQuery(query);
    }

    return std::nullopt;
}

std::optional<Product> ProductRepository::findBySku(const QString& sku)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare(
        "SELECT p.*, c.name as category_name "
        "FROM products p "
        "LEFT JOIN categories c ON p.category_id = c.id "
        "WHERE p.sku = :sku"
    );
    query.bindValue(":sku", sku);

    if (!query.exec()) {
        qCritical() << "Error buscando producto por SKU:" << query.lastError().text();
        return std::nullopt;
    }

    if (query.next()) {
        return mapFromQuery(query);
    }

    return std::nullopt;
}

std::optional<Product> ProductRepository::findByBarcode(const QString& barcode)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare(
        "SELECT p.*, c.name as category_name "
        "FROM products p "
        "LEFT JOIN categories c ON p.category_id = c.id "
        "WHERE p.barcode = :barcode"
    );
    query.bindValue(":barcode", barcode);

    if (!query.exec()) {
        qCritical() << "Error buscando producto por código de barras:" << query.lastError().text();
        return std::nullopt;
    }

    if (query.next()) {
        return mapFromQuery(query);
    }

    return std::nullopt;
}

QList<Product> ProductRepository::findAll(bool activeOnly)
{
    QList<Product> products;
    QSqlQuery query(DatabaseManager::instance().database());
    
    QString sql = 
        "SELECT p.*, c.name as category_name "
        "FROM products p "
        "LEFT JOIN categories c ON p.category_id = c.id ";
    
    if (activeOnly) {
        sql += "WHERE p.active = 1 ";
    }
    
    sql += "ORDER BY p.name";

    if (!query.exec(sql)) {
        qCritical() << "Error obteniendo productos:" << query.lastError().text();
        return products;
    }

    while (query.next()) {
        products.append(mapFromQuery(query));
    }

    return products;
}

QList<Product> ProductRepository::searchByName(const QString& name)
{
    QList<Product> products;
    QSqlQuery query(DatabaseManager::instance().database());
    
    query.prepare(
        "SELECT p.*, c.name as category_name "
        "FROM products p "
        "LEFT JOIN categories c ON p.category_id = c.id "
        "WHERE p.active = 1 AND p.name LIKE :name "
        "ORDER BY p.name"
    );
    query.bindValue(":name", "%" + name + "%");

    if (!query.exec()) {
        qCritical() << "Error buscando productos:" << query.lastError().text();
        return products;
    }

    while (query.next()) {
        products.append(mapFromQuery(query));
    }

    return products;
}

QList<Product> ProductRepository::findByCategory(int categoryId)
{
    QList<Product> products;
    QSqlQuery query(DatabaseManager::instance().database());
    
    query.prepare(
        "SELECT p.*, c.name as category_name "
        "FROM products p "
        "LEFT JOIN categories c ON p.category_id = c.id "
        "WHERE p.category_id = :category_id AND p.active = 1 "
        "ORDER BY p.name"
    );
    query.bindValue(":category_id", categoryId);

    if (!query.exec()) {
        qCritical() << "Error obteniendo productos por categoría:" << query.lastError().text();
        return products;
    }

    while (query.next()) {
        products.append(mapFromQuery(query));
    }

    return products;
}

QList<Product> ProductRepository::findLowStock()
{
    QList<Product> products;
    QSqlQuery query(DatabaseManager::instance().database());
    
    if (!query.exec(
        "SELECT p.*, c.name as category_name "
        "FROM products p "
        "LEFT JOIN categories c ON p.category_id = c.id "
        "WHERE p.current_stock <= p.minimum_stock AND p.active = 1 "
        "ORDER BY p.current_stock ASC"
    )) {
        qCritical() << "Error obteniendo productos con stock bajo:" << query.lastError().text();
        return products;
    }

    while (query.next()) {
        products.append(mapFromQuery(query));
    }

    return products;
}

bool ProductRepository::updateStock(int productId, double newStock)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare("UPDATE products SET current_stock = :stock WHERE id = :id");
    query.bindValue(":stock", newStock);
    query.bindValue(":id", productId);
    
    if (!query.exec()) {
        qCritical() << "Error actualizando stock:" << query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}

int ProductRepository::count()
{
    QSqlQuery query(DatabaseManager::instance().database());
    if (!query.exec("SELECT COUNT(*) FROM products WHERE active = 1")) {
        return 0;
    }

    if (query.next()) {
        return query.value(0).toInt();
    }

    return 0;
}

Product ProductRepository::mapFromQuery(const QSqlQuery& query)
{
    Product product;
    product.id = query.value("id").toInt();
    product.name = query.value("name").toString();
    product.sku = query.value("sku").toString();
    product.barcode = query.value("barcode").toString();
    product.categoryId = query.value("category_id").toInt();
    product.categoryName = query.value("category_name").toString();
    product.currentStock = query.value("current_stock").toDouble();
    product.minimumStock = query.value("minimum_stock").toDouble();
    product.purchasePrice = query.value("purchase_price").toDouble();
    product.salePrice = query.value("sale_price").toDouble();
    product.description = query.value("description").toString();
    product.imagePath = query.value("image_path").toString();
    product.active = query.value("active").toBool();
    product.createdAt = QDateTime::fromString(query.value("created_at").toString(), Qt::ISODate);
    product.updatedAt = QDateTime::fromString(query.value("updated_at").toString(), Qt::ISODate);
    return product;
}
