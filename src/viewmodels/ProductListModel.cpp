#include "ProductListModel.h"
#include "../services/ProductService.h"
#include <QDebug>

ProductListModel::ProductListModel(QObject *parent)
    : QAbstractListModel(parent)
{
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
    ProductService service;
    QString errorMessage;

    Product product;
    product.name = productData.value("name").toString();
    product.sku = productData.value("sku").toString();
    product.barcode = productData.value("barcode").toString();
    product.categoryId = productData.value("categoryId", 0).toInt();
    product.currentStock = productData.value("currentStock", 0.0).toDouble();
    product.minimumStock = productData.value("minimumStock", 0.0).toDouble();
    product.purchasePrice = productData.value("purchasePrice", 0.0).toDouble();
    product.salePrice = productData.value("salePrice", 0.0).toDouble();
    product.description = productData.value("description").toString();
    product.active = true;

    if (service.createProduct(product, errorMessage)) {
        loadProducts();
        emit productAdded(product.id);
        return true;
    } else {
        emit errorOccurred(errorMessage);
        return false;
    }
}

bool ProductListModel::updateProduct(int productId, const QVariantMap& productData)
{
    ProductService service;
    QString errorMessage;

    // Obtener producto actual
    auto currentProduct = service.getProduct(productId);
    if (!currentProduct) {
        emit errorOccurred("Producto no encontrado");
        return false;
    }

    // Actualizar campos
    currentProduct->name = productData.value("name", currentProduct->name).toString();
    currentProduct->sku = productData.value("sku", currentProduct->sku).toString();
    currentProduct->barcode = productData.value("barcode", currentProduct->barcode).toString();
    currentProduct->categoryId = productData.value("categoryId", currentProduct->categoryId).toInt();
    currentProduct->currentStock = productData.value("currentStock", currentProduct->currentStock).toDouble();
    currentProduct->minimumStock = productData.value("minimumStock", currentProduct->minimumStock).toDouble();
    currentProduct->purchasePrice = productData.value("purchasePrice", currentProduct->purchasePrice).toDouble();
    currentProduct->salePrice = productData.value("salePrice", currentProduct->salePrice).toDouble();
    currentProduct->description = productData.value("description", currentProduct->description).toString();

    if (service.updateProduct(*currentProduct, errorMessage)) {
        loadProducts();
        emit productUpdated(productId);
        return true;
    } else {
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
        return true;
    } else {
        emit errorOccurred(errorMessage);
        return false;
    }
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
