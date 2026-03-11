#include "ProductListModel.h"
#include "../services/ProductService.h"
#include "../database/DatabaseManager.h"
#include "xlsxdocument.h"
#include "xlsxformat.h"
#include <QDebug>
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>
#include <QSettings>
#include <QRegularExpression>

ProductListModel::ProductListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    loadAvailableCategories();
}

int ProductListModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_products.count();
}

QVariant ProductListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_products.count())
        return QVariant();

    const Product& product = m_products.at(index.row());

    switch (role) {
    case IdRole:
        return product.id;
    case NameRole:
        return product.name;
    case SkuRole:
        return product.sku;
    case BarcodeRole:
        return product.barcode;
    case CategoryRole:
        return product.categoryName;
    case CurrentStockRole:
        return product.currentStock;
    case MinimumStockRole:
        return product.minimumStock;
    case PurchasePriceRole:
        return product.purchasePrice;
    case SalePriceRole:
        return product.salePrice;
    case DescriptionRole:
        return product.description;
    case ActiveRole:
        return product.active;
    case IsLowStockRole:
        return product.isLowStock();
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> ProductListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "productId";
    roles[NameRole] = "name";
    roles[SkuRole] = "sku";
    roles[BarcodeRole] = "barcode";
    roles[CategoryRole] = "category";
    roles[CurrentStockRole] = "currentStock";
    roles[MinimumStockRole] = "minimumStock";
    roles[PurchasePriceRole] = "purchasePrice";
    roles[SalePriceRole] = "salePrice";
    roles[DescriptionRole] = "description";
    roles[ActiveRole] = "active";
    roles[IsLowStockRole] = "isLowStock";
    return roles;
}

void ProductListModel::loadProducts()
{
    setIsLoading(true);

    ProductService service;
    auto products = service.getAllProducts(true);

    beginResetModel();
    m_products = products;
    endResetModel();

    emit countChanged();
    setIsLoading(false);
    
    // Recargar categorías también
    loadAvailableCategories();
}

void ProductListModel::searchProducts(const QString& searchTerm)
{
    setIsLoading(true);

    ProductService service;
    auto products = service.searchProducts(searchTerm);

    beginResetModel();
    m_products = products;
    endResetModel();

    emit countChanged();
    setIsLoading(false);
}

void ProductListModel::filterByCategory(int categoryId)
{
    setIsLoading(true);

    ProductService service;
    auto products = service.getProductsByCategory(categoryId);

    beginResetModel();
    m_products = products;
    endResetModel();

    emit countChanged();
    setIsLoading(false);
}

void ProductListModel::filterByCategoryName(const QString& categoryName)
{
    setIsLoading(true);

    if (categoryName.isEmpty() || categoryName == "Todas") {
        // Si no hay categoría o es "Todas", cargar todos los productos
        loadProducts();
        return;
    }

    ProductService service;
    auto allProducts = service.getAllProducts(true);
    
    // Filtrar por nombre de categoría
    QList<Product> filteredProducts;
    for (const auto& product : allProducts) {
        if (product.categoryName.compare(categoryName, Qt::CaseInsensitive) == 0) {
            filteredProducts.append(product);
        }
    }

    beginResetModel();
    m_products = filteredProducts;
    endResetModel();

    emit countChanged();
    setIsLoading(false);
}

QStringList ProductListModel::getAvailableCategories()
{
    return m_availableCategories;
}

void ProductListModel::loadAvailableCategories()
{
    QStringList categories;
    categories.append("Todas"); // Agregar opción "Todas" al inicio
    
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare("SELECT name FROM categories ORDER BY name ASC");
    
    if (query.exec()) {
        while (query.next()) {
            QString categoryName = query.value(0).toString();
            if (!categoryName.isEmpty()) {
                categories.append(categoryName);
            }
        }
    } else {
        qWarning() << "Error obteniendo categorías:" << query.lastError().text();
    }
    
    qDebug() << "Categorías cargadas:" << categories;
    
    if (m_availableCategories != categories) {
        m_availableCategories = categories;
        emit availableCategoriesChanged();
    }
}

void ProductListModel::filterLowStock()
{
    setIsLoading(true);

    ProductService service;
    auto products = service.getLowStockProducts();

    beginResetModel();
    m_products = products;
    endResetModel();

    emit countChanged();
    setIsLoading(false);
}

QVariantMap ProductListModel::getProduct(int index) const
{
    if (index < 0 || index >= m_products.count())
        return QVariantMap();

    return productToVariantMap(m_products.at(index));
}

bool ProductListModel::addProduct(const QVariantMap& productData)
{
    // Validar datos primero
    QString validationError = validateProductData(productData);
    if (!validationError.isEmpty()) {
        emit errorOccurred(validationError);
        return false;
    }

    ProductService service;
    QString errorMessage;

    Product product;
    product.name = productData.value("name").toString().trimmed();
    product.sku = productData.value("sku").toString().trimmed();
    product.barcode = productData.value("barcode").toString().trimmed();
    product.categoryName = productData.value("category").toString().trimmed();
    product.categoryId = productData.value("categoryId", 0).toInt();
    product.currentStock = productData.value("currentStock", 0.0).toDouble();
    product.minimumStock = productData.value("minimumStock", 0.0).toDouble();
    product.purchasePrice = productData.value("purchasePrice", 0.0).toDouble();
    product.salePrice = productData.value("salePrice", 0.0).toDouble();
    product.description = productData.value("description").toString().trimmed();
    product.active = true;

    if (service.createProduct(product, errorMessage)) {
        loadProducts();
        emit productAdded(product.id);
        emit operationSucceeded("Producto creado exitosamente");
        return true;
    } else {
        emit errorOccurred(errorMessage);
        return false;
    }
}

bool ProductListModel::updateProduct(int productId, const QVariantMap& productData)
{
    qDebug() << "[ProductListModel] updateProduct llamado con ID:" << productId;
    qDebug() << "[ProductListModel] Datos recibidos:" << productData;
    
    // Validar datos primero
    QString validationError = validateProductData(productData);
    if (!validationError.isEmpty()) {
        qDebug() << "[ProductListModel] Error de validación:" << validationError;
        emit errorOccurred(validationError);
        return false;
    }

    ProductService service;
    QString errorMessage;

    // Obtener producto actual
    auto currentProduct = service.getProduct(productId);
    if (!currentProduct) {
        qDebug() << "[ProductListModel] Producto no encontrado con ID:" << productId;
        emit errorOccurred("Producto no encontrado");
        return false;
    }

    qDebug() << "[ProductListModel] Stock actual en BD:" << currentProduct->currentStock;
    qDebug() << "[ProductListModel] Nuevo stock a guardar:" << productData.value("currentStock").toDouble();

    // Actualizar campos (aplicar trim)
    currentProduct->name = productData.value("name", currentProduct->name).toString().trimmed();
    currentProduct->sku = productData.value("sku", currentProduct->sku).toString().trimmed();
    currentProduct->barcode = productData.value("barcode", currentProduct->barcode).toString().trimmed();
    
    // Actualizar categoría - usar nombre de categoría si está disponible
    if (productData.contains("category")) {
        currentProduct->categoryName = productData.value("category").toString().trimmed();
        // categoryId se mantiene igual (la BD no usa IDs reales de categoría por ahora)
    }
    
    currentProduct->currentStock = productData.value("currentStock", currentProduct->currentStock).toDouble();
    currentProduct->minimumStock = productData.value("minimumStock", currentProduct->minimumStock).toDouble();
    currentProduct->purchasePrice = productData.value("purchasePrice", currentProduct->purchasePrice).toDouble();
    currentProduct->salePrice = productData.value("salePrice", currentProduct->salePrice).toDouble();
    currentProduct->description = productData.value("description", currentProduct->description).toString().trimmed();

    if (service.updateProduct(*currentProduct, errorMessage)) {
        loadProducts();
        emit productUpdated(productId);
        emit operationSucceeded("Producto actualizado exitosamente");
        qDebug() << "Producto actualizado correctamente. ID:" << productId;
        return true;
    } else {
        qDebug() << "Error al actualizar producto:" << errorMessage;
        emit errorOccurred(errorMessage);
        return false;
    }
}

bool ProductListModel::deleteProduct(int productId)
{
    ProductService service;
    QString errorMessage;

    if (service.deleteProduct(productId, errorMessage)) {
        // Recargar lista
        loadProducts();
        emit productDeleted(productId);
        emit operationSucceeded("Producto eliminado exitosamente");
        return true;
    } else {
        emit errorOccurred(errorMessage);
        return false;
    }
}

bool ProductListModel::deleteAllProducts()
{
    ProductRepository repository;
    
    // Obtener todos los productos
    auto allProducts = repository.findAll();
    
    if (allProducts.isEmpty()) {
        emit errorOccurred("No hay productos para eliminar");
        return false;
    }
    
    qDebug() << "Eliminando" << allProducts.size() << "productos...";
    
    int deletedCount = 0;
    int failedCount = 0;
    
    for (const auto& product : allProducts) {
        QString errorMessage;
        ProductService service;
        if (service.deleteProduct(product.id, errorMessage)) {
            deletedCount++;
        } else {
            failedCount++;
            qWarning() << "Error eliminando producto ID" << product.id << ":" << errorMessage;
        }
    }
    
    qDebug() << "Eliminados:" << deletedCount << "| Fallidos:" << failedCount;
    
    // Recargar lista
    loadProducts();
    
    if (failedCount == 0) {
        emit operationSucceeded(QString("Se eliminaron %1 productos exitosamente").arg(deletedCount));
        return true;
    } else {
        emit errorOccurred(QString("Se eliminaron %1 productos. %2 fallaron").arg(deletedCount).arg(failedCount));
        return false;
    }
}

bool ProductListModel::restockProduct(int productId, double quantity)
{
    if (quantity <= 0) {
        emit errorOccurred("La cantidad debe ser mayor a cero");
        return false;
    }
    
    ProductRepository repository;
    
    if (repository.incrementStock(productId, quantity)) {
        // Recargar lista para actualizar la vista
        loadProducts();
        emit operationSucceeded(QString("Se agregaron %1 unidades al inventario").arg(quantity));
        return true;
    } else {
        emit errorOccurred("Error al reponer el inventario");
        return false;
    }
}

QString ProductListModel::validateProductData(const QVariantMap& productData) const
{
    // Validar campos obligatorios
    QString name = productData.value("name").toString().trimmed();
    if (name.isEmpty()) {
        return "El nombre del producto es obligatorio";
    }

    QString sku = productData.value("sku").toString().trimmed();
    if (sku.isEmpty()) {
        return "El código SKU es obligatorio";
    }

    double salePrice = productData.value("salePrice", -1.0).toDouble();
    if (salePrice <= 0) {
        return "El precio de venta debe ser mayor a 0";
    }

    double currentStock = productData.value("currentStock", 0.0).toDouble();
    if (currentStock < 0) {
        return "El stock no puede ser negativo";
    }

    double purchasePrice = productData.value("purchasePrice", 0.0).toDouble();
    if (purchasePrice < 0) {
        return "El precio de compra no puede ser negativo";
    }

    return QString(); // Sin errores
}

QVariantMap ProductListModel::getProductForEdit(int productId) const
{
    // Buscar producto por ID en la lista actual
    for (const auto& product : m_products) {
        if (product.id == productId) {
            return productToVariantMap(product);
        }
    }

    // Si no está en caché, consultar desde el servicio
    ProductService service;
    auto product = service.getProduct(productId);
    if (product) {
        return productToVariantMap(*product);
    }

    qWarning() << "Producto no encontrado con ID:" << productId;
    return QVariantMap();
}

bool ProductListModel::hasProductWithBarcode(const QString& barcode) const
{
    if (barcode.trimmed().isEmpty()) {
        return false;
    }

    // Buscar en la lista actual de productos
    for (const auto& product : m_products) {
        if (product.barcode == barcode || product.sku == barcode) {
            return true;
        }
    }

    // Si no está en caché, consultar en la base de datos
    ProductService service;
    auto product = service.getProductByBarcode(barcode);
    return product.has_value();
}

void ProductListModel::setIsLoading(bool loading)
{
    if (m_isLoading != loading) {
        m_isLoading = loading;
        emit isLoadingChanged();
    }
}

QVariantMap ProductListModel::productToVariantMap(const Product& product) const
{
    QVariantMap map;
    map["id"] = product.id;
    map["name"] = product.name;
    map["sku"] = product.sku;
    map["barcode"] = product.barcode;
    map["categoryId"] = product.categoryId;
    map["category"] = product.categoryName;
    map["currentStock"] = product.currentStock;
    map["minimumStock"] = product.minimumStock;
    map["purchasePrice"] = product.purchasePrice;
    map["salePrice"] = product.salePrice;
    map["description"] = product.description;
    map["active"] = product.active;
    map["isLowStock"] = product.isLowStock();
    return map;
}

void ProductListModel::setIsExporting(bool exporting)
{
    if (m_isExporting != exporting) {
        m_isExporting = exporting;
        emit isExportingChanged();
    }
}

void ProductListModel::setExportProgress(int progress)
{
    if (m_exportProgress != progress) {
        m_exportProgress = progress;
        emit exportProgressChanged();
    }
}

void ProductListModel::setExportProgressMessage(const QString& message)
{
    if (m_exportProgressMessage != message) {
        m_exportProgressMessage = message;
        emit exportProgressMessageChanged();
    }
}

bool ProductListModel::exportToExcel()
{
    qDebug() << "=== Iniciando exportación a Excel ===";
    
    setIsExporting(true);
    setExportProgress(0);
    setExportProgressMessage("Iniciando exportación...");
    
    try {
        // Obtener todos los productos de la base de datos
        setExportProgressMessage("Consultando productos...");
        setExportProgress(10);
        
        ProductService service;
        auto allProducts = service.getAllProducts();
        
        if (allProducts.empty()) {
            qWarning() << "No hay productos para exportar";
            setIsExporting(false);
            emit exportCompleted(false, "");
            emit errorOccurred("No hay productos para exportar");
            return false;
        }
        
        qDebug() << "Productos encontrados:" << allProducts.size();
        setExportProgress(20);
        
        // Crear documento Excel
        setExportProgressMessage("Creando archivo Excel...");
        QXlsx::Document xlsx;
        
        // Configurar formato de cabecera
        QXlsx::Format headerFormat;
        headerFormat.setFontBold(true);
        headerFormat.setFontSize(11);
        headerFormat.setHorizontalAlignment(QXlsx::Format::AlignHCenter);
        headerFormat.setVerticalAlignment(QXlsx::Format::AlignVCenter);
        headerFormat.setPatternBackgroundColor(QColor(68, 114, 196)); // Azul
        headerFormat.setFontColor(QColor(Qt::white));
        headerFormat.setBorderStyle(QXlsx::Format::BorderThin);
        
        // Escribir cabeceras
        setExportProgressMessage("Escribiendo cabeceras...");
        setExportProgress(30);
        
        xlsx.write(1, 1, "ID", headerFormat);
        xlsx.write(1, 2, "Nombre", headerFormat);
        xlsx.write(1, 3, "SKU", headerFormat);
        xlsx.write(1, 4, "Código de Barras", headerFormat);
        xlsx.write(1, 5, "Categoría", headerFormat);
        xlsx.write(1, 6, "Stock Actual", headerFormat);
        xlsx.write(1, 7, "Stock Mínimo", headerFormat);
        xlsx.write(1, 8, "Precio Compra", headerFormat);
        xlsx.write(1, 9, "Precio Venta", headerFormat);
        xlsx.write(1, 10, "Descripción", headerFormat);
        xlsx.write(1, 11, "Estado", headerFormat);
        
        // Ajustar anchos de columna
        xlsx.setColumnWidth(1, 6);   // ID
        xlsx.setColumnWidth(2, 30);  // Nombre
        xlsx.setColumnWidth(3, 15);  // SKU
        xlsx.setColumnWidth(4, 18);  // Código de Barras
        xlsx.setColumnWidth(5, 20);  // Categoría
        xlsx.setColumnWidth(6, 12);  // Stock Actual
        xlsx.setColumnWidth(7, 12);  // Stock Mínimo
        xlsx.setColumnWidth(8, 14);  // Precio Compra
        xlsx.setColumnWidth(9, 14);  // Precio Venta
        xlsx.setColumnWidth(10, 40); // Descripción
        xlsx.setColumnWidth(11, 10); // Estado
        
        // Formato para datos
        QXlsx::Format dataFormat;
        dataFormat.setFontSize(10);
        dataFormat.setBorderStyle(QXlsx::Format::BorderThin);
        dataFormat.setBorderColor(QColor(Qt::lightGray));
        
        QXlsx::Format numberFormat;
        numberFormat.setFontSize(10);
        numberFormat.setBorderStyle(QXlsx::Format::BorderThin);
        numberFormat.setBorderColor(QColor(Qt::lightGray));
        numberFormat.setHorizontalAlignment(QXlsx::Format::AlignRight);
        
        QXlsx::Format priceFormat;
        priceFormat.setFontSize(10);
        priceFormat.setBorderStyle(QXlsx::Format::BorderThin);
        priceFormat.setBorderColor(QColor(Qt::lightGray));
        priceFormat.setHorizontalAlignment(QXlsx::Format::AlignRight);
        priceFormat.setNumberFormat("S/ #,##0.00");
        
        // Escribir datos de productos
        setExportProgressMessage("Escribiendo productos...");
        int totalProducts = allProducts.size();
        int row = 2; // Empezar después de la cabecera
        int processedCount = 0;
        
        for (const auto& product : allProducts) {
            xlsx.write(row, 1, product.id, numberFormat);
            xlsx.write(row, 2, product.name, dataFormat);
            xlsx.write(row, 3, product.sku, dataFormat);
            xlsx.write(row, 4, product.barcode, dataFormat);
            xlsx.write(row, 5, product.categoryName, dataFormat);
            xlsx.write(row, 6, product.currentStock, numberFormat);
            xlsx.write(row, 7, product.minimumStock, numberFormat);
            xlsx.write(row, 8, product.purchasePrice, priceFormat);
            xlsx.write(row, 9, product.salePrice, priceFormat);
            xlsx.write(row, 10, product.description, dataFormat);
            xlsx.write(row, 11, product.active ? "Activo" : "Inactivo", dataFormat);
            
            row++;
            processedCount++;
            
            // Actualizar progreso cada 10 productos
            if (processedCount % 10 == 0 || processedCount == totalProducts) {
                int progress = 30 + (processedCount * 50 / totalProducts);
                setExportProgress(progress);
                setExportProgressMessage(QString("Escribiendo productos... %1/%2")
                    .arg(processedCount)
                    .arg(totalProducts));
            }
        }
        
        // Guardar archivo
        setExportProgressMessage("Guardando archivo...");
        setExportProgress(85);
        
        // Obtener información del negocio
        QSettings settings("SistemaInventario", "Config");
        QString businessName = settings.value("businessName", "Mi Negocio").toString();
        
        // Sanitizar nombre del negocio para carpetas
        QString sanitizedBusinessName = businessName;
        sanitizedBusinessName.replace(QRegularExpression("[^a-zA-Z0-9_]"), "_");
        sanitizedBusinessName.replace(QRegularExpression("_+"), "_");
        
        // Construir estructura de carpetas: {reportsFolder}/{NombreNegocio}/Versiones de inventario/
        QString reportsBaseFolder = settings.value("reportsFolder", "C:/Reportes_SistemaInventario").toString();
        QString baseDir = reportsBaseFolder + "/" + sanitizedBusinessName;
        QString reportsDir = baseDir + "/Versiones de inventario";
        
        // Crear directorios si no existen
        QDir dir;
        if (!dir.exists(reportsDir)) {
            qDebug() << "Creando estructura de directorios:" << reportsDir;
            if (!dir.mkpath(reportsDir)) {
                qCritical() << "Error al crear directorio de inventario:" << reportsDir;
                setIsExporting(false);
                emit exportCompleted(false, "");
                emit errorOccurred("Error al crear directorio de inventario");
                return false;
            }
        }
        
        QString timestamp = QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss");
        QString fileName = QString("Inventario_%1.xlsx").arg(timestamp);
        QString fullPath = reportsDir + "/" + fileName;
        
        qDebug() << "Guardando archivo en:" << fullPath;
        
        if (!xlsx.saveAs(fullPath)) {
            qWarning() << "Error al guardar el archivo Excel";
            setIsExporting(false);
            emit exportCompleted(false, "");
            emit errorOccurred("Error al guardar el archivo Excel");
            return false;
        }
        
        setExportProgressMessage("Exportación completada");
        setExportProgress(100);
        
        qDebug() << "Exportación exitosa:" << fullPath;
        
        setIsExporting(false);
        emit exportCompleted(true, fullPath);
        emit operationSucceeded(QString("Inventario exportado: %1").arg(fileName));
        
        return true;
        
    } catch (const std::exception& e) {
        qWarning() << "Excepción durante exportación:" << e.what();
        setIsExporting(false);
        emit exportCompleted(false, "");
        emit errorOccurred(QString("Error durante exportación: %1").arg(e.what()));
        return false;
    } catch (...) {
        qWarning() << "Error desconocido durante exportación";
        setIsExporting(false);
        emit exportCompleted(false, "");
        emit errorOccurred("Error desconocido durante exportación");
        return false;
    }
}
