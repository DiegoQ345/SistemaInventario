#include "SalesCartViewModel.h"
#include <QDebug>

// ============================================================================
// CartItemModel Implementation
// ============================================================================

CartItemModel::CartItemModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int CartItemModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_items.count();
}

QVariant CartItemModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_items.count())
        return QVariant();

    const SaleItem& item = m_items[index.row()];

    switch (role) {
    case ProductIdRole:
        return item.productId;
    case ProductNameRole:
        return item.productName;
    case SkuRole:
        return QVariant();  // Necesitarías agregarlo al modelo
    case BarcodeRole:
        return QVariant();  // Necesitarías agregarlo al modelo
    case QuantityRole:
        return item.quantity;
    case UnitPriceRole:
        return item.unitPrice;
    case SubtotalRole:
        return item.subtotal;
    case MaxQuantityRole:
        return m_maxQuantities.value(item.productId, 0.0);
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> CartItemModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[ProductIdRole] = "productId";
    roles[ProductNameRole] = "productName";
    roles[SkuRole] = "sku";
    roles[BarcodeRole] = "barcode";
    roles[QuantityRole] = "quantity";
    roles[UnitPriceRole] = "unitPrice";
    roles[SubtotalRole] = "subtotal";
    roles[MaxQuantityRole] = "maxQuantity";
    return roles;
}

double CartItemModel::subtotal() const
{
    double sum = 0.0;
    for (const auto& item : m_items) {
        sum += item.subtotal;
    }
    return sum;
}

double CartItemModel::total() const
{
    // Por ahora igual al subtotal, pero podría incluir impuestos
    return subtotal();
}

void CartItemModel::addItem(int productId, const QString& productName, 
                            const QString& sku, const QString& barcode,
                            double quantity, double unitPrice, double maxQuantity)
{
    // Verificar si el producto ya está en el carrito
    for (int i = 0; i < m_items.count(); ++i) {
        if (m_items[i].productId == productId) {
            // Actualizar cantidad
            double newQuantity = m_items[i].quantity + quantity;
            if (newQuantity > maxQuantity) {
                emit error(QString("Stock insuficiente. Disponible: %1").arg(maxQuantity));
                return;
            }
            updateQuantity(i, newQuantity);
            return;
        }
    }

    // Agregar nuevo item
    if (quantity > maxQuantity) {
        emit error(QString("Stock insuficiente. Disponible: %1").arg(maxQuantity));
        return;
    }

    SaleItem newItem;
    newItem.productId = productId;
    newItem.productName = productName;
    newItem.quantity = quantity;
    newItem.unitPrice = unitPrice;
    newItem.calculateSubtotal();

    beginInsertRows(QModelIndex(), m_items.count(), m_items.count());
    m_items.append(newItem);
    m_maxQuantities[productId] = maxQuantity;
    endInsertRows();

    emit countChanged();
    notifyTotalsChanged();
    emit itemAdded(productName);
}

void CartItemModel::removeItem(int index)
{
    if (index < 0 || index >= m_items.count())
        return;

    QString productName = m_items[index].productName;
    int productId = m_items[index].productId;

    beginRemoveRows(QModelIndex(), index, index);
    m_items.removeAt(index);
    m_maxQuantities.remove(productId);
    endRemoveRows();

    emit countChanged();
    notifyTotalsChanged();
    emit itemRemoved(productName);
}

void CartItemModel::updateQuantity(int index, double quantity)
{
    if (index < 0 || index >= m_items.count())
        return;

    double maxQty = m_maxQuantities.value(m_items[index].productId, 0.0);
    if (quantity > maxQty) {
        emit error(QString("Stock insuficiente. Disponible: %1").arg(maxQty));
        return;
    }

    if (quantity <= 0) {
        removeItem(index);
        return;
    }

    m_items[index].quantity = quantity;
    m_items[index].calculateSubtotal();

    QModelIndex modelIndex = createIndex(index, 0);
    emit dataChanged(modelIndex, modelIndex);
    notifyTotalsChanged();
    emit quantityUpdated(index);
}

void CartItemModel::clear()
{
    if (m_items.isEmpty())
        return;

    beginResetModel();
    m_items.clear();
    m_maxQuantities.clear();
    endResetModel();

    emit countChanged();
    notifyTotalsChanged();
}

void CartItemModel::notifyTotalsChanged()
{
    emit subtotalChanged();
    emit totalChanged();
}

// ============================================================================
// SalesCartViewModel Implementation
// ============================================================================

SalesCartViewModel::SalesCartViewModel(QObject *parent)
    : QObject(parent)
    , m_cart(new CartItemModel(this))
{
}

SalesCartViewModel::~SalesCartViewModel()
{
}

bool SalesCartViewModel::searchAndAddProduct(const QString& code, double quantity)
{
    if (code.isEmpty()) {
        emit productNotFound(code);
        return false;
    }

    // Buscar por código de barras primero
    auto product = m_productService.getProductByBarcode(code);
    
    // Si no se encuentra, buscar por SKU
    if (!product.has_value()) {
        product = m_productService.getProductBySku(code);
    }

    if (!product.has_value()) {
        emit productNotFound(code);
        return false;
    }

    return addProductById(product->id, quantity);
}

bool SalesCartViewModel::addProductById(int productId, double quantity)
{
    auto product = m_productService.getProduct(productId);
    if (!product.has_value()) {
        emit productNotFound(QString::number(productId));
        return false;
    }

    // Validar stock
    QString errorMsg;
    if (!validateStock(product.value(), quantity, errorMsg)) {
        emit insufficientStock(product->name, product->currentStock, quantity);
        return false;
    }

    // Verificar si ya está en el carrito para ajustar stock disponible
    double alreadyInCart = 0.0;
    for (const auto& item : m_cart->items()) {
        if (item.productId == productId) {
            alreadyInCart = item.quantity;
            break;
        }
    }

    double availableStock = product->currentStock - alreadyInCart;

    m_cart->addItem(
        product->id,
        product->name,
        product->sku,
        product->barcode,
        quantity,
        product->salePrice,
        availableStock
    );

    emit productAdded(product->name, quantity);
    return true;
}

bool SalesCartViewModel::processSale(int customerId, const QString& customerName,
                                     int paymentMethodId, const QString& paymentMethodName,
                                     double discount, const QString& notes)
{
    if (m_cart->items().isEmpty()) {
        emit saleFailed("El carrito está vacío");
        return false;
    }

    setIsProcessing(true);

    // Crear venta
    Sale sale;
    sale.customerId = customerId;
    sale.customerName = customerName;
    sale.paymentMethodId = paymentMethodId;
    sale.paymentMethodName = paymentMethodName;
    sale.discount = discount;
    sale.notes = notes;
    sale.items = m_cart->items();
    sale.calculateTotals();

    QString errorMessage;
    bool success = m_salesService.createSale(sale, errorMessage);

    if (success) {
        m_lastInvoiceNumber = sale.invoiceNumber;
        emit lastInvoiceNumberChanged();
        emit saleCompleted(sale.invoiceNumber, sale.total);
        m_cart->clear();
    } else {
        emit saleFailed(errorMessage);
    }

    setIsProcessing(false);
    return success;
}

void SalesCartViewModel::cancelSale()
{
    m_cart->clear();
}

QVariantMap SalesCartViewModel::getProductInfo(int productId)
{
    QVariantMap info;
    auto product = m_productService.getProduct(productId);
    
    if (product.has_value()) {
        info["id"] = product->id;
        info["name"] = product->name;
        info["sku"] = product->sku;
        info["barcode"] = product->barcode;
        info["currentStock"] = product->currentStock;
        info["salePrice"] = product->salePrice;
        info["categoryId"] = product->categoryId;
        info["categoryName"] = product->categoryName;
    }
    
    return info;
}

void SalesCartViewModel::setIsProcessing(bool processing)
{
    if (m_isProcessing != processing) {
        m_isProcessing = processing;
        emit isProcessingChanged();
    }
}

bool SalesCartViewModel::validateStock(const Product& product, double quantity, QString& errorMsg)
{
    if (!product.active) {
        errorMsg = "El producto no está activo";
        return false;
    }

    if (product.currentStock < quantity) {
        errorMsg = QString("Stock insuficiente. Disponible: %1").arg(product.currentStock);
        return false;
    }

    return true;
}
