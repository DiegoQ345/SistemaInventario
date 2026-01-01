#include "ProductService.h"
#include "../database/DatabaseManager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>

ProductService::ProductService(QObject *parent)
    : QObject(parent)
{
}

bool ProductService::createProduct(Product& product, QString& errorMessage)
{
    // Validar datos
    if (!validateProduct(product, errorMessage)) {
        return false;
    }

    // Crear producto
    int productId = m_productRepo.create(product);
    if (productId == 0) {
        errorMessage = "Error al guardar el producto en la base de datos";
        return false;
    }

    // Registrar stock inicial si es mayor a 0
    if (product.currentStock > 0) {
        logStockMovement(productId, getMovementTypeId("AJUSTE_POSITIVO"),
                        product.currentStock, 0, product.currentStock,
                        product.purchasePrice, "Stock inicial", "");
    }

    emit productCreated(productId);
    return true;
}

bool ProductService::updateProduct(const Product& product, QString& errorMessage)
{
    // Validar datos
    if (!validateProduct(product, errorMessage)) {
        return false;
    }

    // Obtener producto actual para comparar stock
    auto currentProduct = m_productRepo.findById(product.id);
    if (!currentProduct) {
        errorMessage = "Producto no encontrado";
        return false;
    }

    // Actualizar producto
    if (!m_productRepo.update(product)) {
        errorMessage = "Error al actualizar el producto";
        return false;
    }

    // Verificar si el stock cambió (aunque no debería cambiar directamente, solo por movimientos)
    if (currentProduct->currentStock != product.currentStock) {
        emit stockChanged(product.id, currentProduct->currentStock, product.currentStock);
        checkLowStock(product);
    }

    emit productUpdated(product.id);
    return true;
}

bool ProductService::deleteProduct(int productId, QString& errorMessage)
{
    // Verificar que el producto existe
    auto product = m_productRepo.findById(productId);
    if (!product) {
        errorMessage = "Producto no encontrado";
        return false;
    }

    // Verificar que no tenga movimientos recientes (opcional)
    // Por ahora solo hacemos soft delete

    if (!m_productRepo.remove(productId)) {
        errorMessage = "Error al eliminar el producto";
        return false;
    }

    emit productDeleted(productId);
    return true;
}

std::optional<Product> ProductService::getProduct(int productId)
{
    return m_productRepo.findById(productId);
}

std::optional<Product> ProductService::getProductBySku(const QString& sku)
{
    return m_productRepo.findBySku(sku);
}

std::optional<Product> ProductService::getProductByBarcode(const QString& barcode)
{
    return m_productRepo.findByBarcode(barcode);
}

QList<Product> ProductService::getAllProducts(bool activeOnly)
{
    return m_productRepo.findAll(activeOnly);
}

QList<Product> ProductService::searchProducts(const QString& searchTerm)
{
    return m_productRepo.searchByName(searchTerm);
}

QList<Product> ProductService::getProductsByCategory(int categoryId)
{
    return m_productRepo.findByCategory(categoryId);
}

QList<Product> ProductService::getLowStockProducts()
{
    return m_productRepo.findLowStock();
}

bool ProductService::registerStockMovement(int productId, const QString& movementTypeCode,
                                          double quantity, double unitPrice,
                                          const QString& reference, const QString& notes,
                                          QString& errorMessage)
{
    qDebug() << "ProductService::registerStockMovement - Product:" << productId << "Type:" << movementTypeCode << "Quantity:" << quantity;
    
    // Obtener producto actual
    auto product = m_productRepo.findById(productId);
    if (!product) {
        errorMessage = "Producto no encontrado";
        qWarning() << "  " << errorMessage;
        return false;
    }

    // Obtener tipo de movimiento
    int movementTypeId = getMovementTypeId(movementTypeCode);
    if (movementTypeId == 0) {
        errorMessage = "Tipo de movimiento inválido";
        qWarning() << "  " << errorMessage;
        return false;
    }

    // Calcular nuevo stock
    double previousStock = product->currentStock;
    double newStock = previousStock;

    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare("SELECT affects_stock FROM movement_types WHERE id = :id");
    query.bindValue(":id", movementTypeId);
    
    if (!query.exec() || !query.next()) {
        errorMessage = "Error obteniendo tipo de movimiento";
        qWarning() << "  " << errorMessage;
        return false;
    }

    int affectsStock = query.value(0).toInt();
    newStock += (quantity * affectsStock);
    
    qDebug() << "  Previous stock:" << previousStock << "Affects:" << affectsStock << "New stock:" << newStock;

    // Validar que el stock no quede negativo
    if (newStock < 0) {
        errorMessage = QString("Stock insuficiente. Stock actual: %1, cantidad solicitada: %2")
                          .arg(previousStock).arg(quantity);
        qWarning() << "  " << errorMessage;
        return false;
    }

    // NO iniciar transacción aquí - debe ser manejada por el servicio que llama (SalesService)
    // La transacción ya fue iniciada por SalesService::createSale()

    // Actualizar stock del producto
    if (!m_productRepo.updateStock(productId, newStock)) {
        errorMessage = "Error actualizando stock";
        qCritical() << "  " << errorMessage;
        return false;
    }
    
    qDebug() << "  Stock updated successfully";

    // Registrar movimiento
    if (!logStockMovement(productId, movementTypeId, quantity, previousStock, newStock,
                         unitPrice, reference, notes)) {
        errorMessage = "Error registrando movimiento";
        qCritical() << "  " << errorMessage;
        return false;
    }
    
    qDebug() << "  Movement logged successfully";

    // NO confirmar transacción aquí - la maneja el servicio superior
    // SalesService::createSale() hará el commit de toda la transacción

    emit stockChanged(productId, previousStock, newStock);

    // Verificar stock bajo
    product->currentStock = newStock;
    checkLowStock(*product);

    return true;
}

bool ProductService::adjustStock(int productId, double newStock, const QString& reason, QString& errorMessage)
{
    auto product = m_productRepo.findById(productId);
    if (!product) {
        errorMessage = "Producto no encontrado";
        return false;
    }

    double previousStock = product->currentStock;
    double difference = newStock - previousStock;

    if (difference == 0) {
        return true;  // Sin cambios
    }

    QString movementCode = (difference > 0) ? "AJUSTE_POSITIVO" : "AJUSTE_NEGATIVO";
    
    return registerStockMovement(productId, movementCode, qAbs(difference), 0, reason, "", errorMessage);
}

QList<StockMovement> ProductService::getStockHistory(int productId)
{
    QList<StockMovement> movements;
    QSqlQuery query(DatabaseManager::instance().database());
    
    query.prepare(
        "SELECT sm.*, mt.name as movement_type_name, mt.code as movement_type_code "
        "FROM stock_movements sm "
        "INNER JOIN movement_types mt ON sm.movement_type_id = mt.id "
        "WHERE sm.product_id = :product_id "
        "ORDER BY sm.created_at DESC"
    );
    query.bindValue(":product_id", productId);

    if (!query.exec()) {
        qCritical() << "Error obteniendo historial de stock:" << query.lastError().text();
        return movements;
    }

    while (query.next()) {
        StockMovement movement;
        movement.id = query.value("id").toInt();
        movement.productId = query.value("product_id").toInt();
        movement.movementTypeId = query.value("movement_type_id").toInt();
        movement.movementTypeName = query.value("movement_type_name").toString();
        movement.movementTypeCode = query.value("movement_type_code").toString();
        movement.quantity = query.value("quantity").toDouble();
        movement.previousStock = query.value("previous_stock").toDouble();
        movement.newStock = query.value("new_stock").toDouble();
        movement.unitPrice = query.value("unit_price").toDouble();
        movement.reference = query.value("reference").toString();
        movement.notes = query.value("notes").toString();
        movement.createdAt = QDateTime::fromString(query.value("created_at").toString(), Qt::ISODate);
        movement.createdBy = query.value("created_by").toString();
        movements.append(movement);
    }

    return movements;
}

bool ProductService::isSkuUnique(const QString& sku, int excludeProductId)
{
    if (sku.isEmpty()) return true;  // SKU vacío es válido

    auto existingProduct = m_productRepo.findBySku(sku);
    if (!existingProduct) return true;

    return existingProduct->id == excludeProductId;
}

bool ProductService::isBarcodeUnique(const QString& barcode, int excludeProductId)
{
    if (barcode.isEmpty()) return true;  // Código de barras vacío es válido

    auto existingProduct = m_productRepo.findByBarcode(barcode);
    if (!existingProduct) return true;

    return existingProduct->id == excludeProductId;
}

bool ProductService::validateProduct(const Product& product, QString& errorMessage)
{
    if (product.name.trimmed().isEmpty()) {
        errorMessage = "El nombre del producto es obligatorio";
        return false;
    }

    if (product.salePrice < 0) {
        errorMessage = "El precio de venta no puede ser negativo";
        return false;
    }

    if (product.purchasePrice < 0) {
        errorMessage = "El precio de compra no puede ser negativo";
        return false;
    }

    if (product.minimumStock < 0) {
        errorMessage = "El stock mínimo no puede ser negativo";
        return false;
    }

    // Validar unicidad de SKU
    if (!product.sku.isEmpty() && !isSkuUnique(product.sku, product.id)) {
        errorMessage = QString("El SKU '%1' ya está en uso").arg(product.sku);
        return false;
    }

    // Validar unicidad de código de barras
    if (!product.barcode.isEmpty() && !isBarcodeUnique(product.barcode, product.id)) {
        errorMessage = QString("El código de barras '%1' ya está en uso").arg(product.barcode);
        return false;
    }

    return true;
}

void ProductService::checkLowStock(const Product& product)
{
    if (product.isLowStock()) {
        emit lowStockAlert(product.id, product.name, product.currentStock);
    }
}

bool ProductService::logStockMovement(int productId, int movementTypeId, double quantity,
                                     double previousStock, double newStock, double unitPrice,
                                     const QString& reference, const QString& notes)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare(
        "INSERT INTO stock_movements (product_id, movement_type_id, quantity, "
        "previous_stock, new_stock, unit_price, reference, notes) "
        "VALUES (:product_id, :movement_type_id, :quantity, :previous_stock, "
        ":new_stock, :unit_price, :reference, :notes)"
    );

    query.bindValue(":product_id", productId);
    query.bindValue(":movement_type_id", movementTypeId);
    query.bindValue(":quantity", quantity);
    query.bindValue(":previous_stock", previousStock);
    query.bindValue(":new_stock", newStock);
    query.bindValue(":unit_price", unitPrice);
    query.bindValue(":reference", reference);
    query.bindValue(":notes", notes);

    if (!query.exec()) {
        qCritical() << "Error registrando movimiento de stock:" << query.lastError().text();
        return false;
    }

    return true;
}

int ProductService::getMovementTypeId(const QString& code)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare("SELECT id FROM movement_types WHERE code = :code");
    query.bindValue(":code", code);

    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }

    return 0;
}
