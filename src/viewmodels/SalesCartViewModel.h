#ifndef SALESCARTVIEWMODEL_H
#define SALESCARTVIEWMODEL_H

#include "../models/Sale.h"
#include "../models/Product.h"
#include "../services/SalesService.h"
#include "../services/ProductService.h"
#include <QAbstractListModel>
#include <QObject>
#include <qqml.h>

/**
 * @brief Modelo para items del carrito de compras
 */
class CartItemModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(double subtotal READ subtotal NOTIFY subtotalChanged)
    Q_PROPERTY(double total READ total NOTIFY totalChanged)
    Q_PROPERTY(QVariantList itemsAsVariantList READ itemsAsVariantList NOTIFY countChanged)

public:
    enum CartItemRoles {
        ProductIdRole = Qt::UserRole + 1,
        ProductNameRole,
        SkuRole,
        BarcodeRole,
        QuantityRole,
        UnitPriceRole,
        SubtotalRole,
        MaxQuantityRole  // Stock disponible
    };

    explicit CartItemModel(QObject *parent = nullptr);

    // QAbstractListModel implementation
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Getters
    double subtotal() const;
    double total() const;
    const QList<SaleItem>& items() const { return m_items; }

public slots:
    void addItem(int productId, const QString& productName, const QString& sku,
                 const QString& barcode, double quantity, double unitPrice, 
                 double maxQuantity);
    void removeItem(int index);
    void updateQuantity(int index, double quantity);
    void clear();
    
    // Métodos que operan por productId (mejor para QML)
    Q_INVOKABLE void removeItemByProductId(int productId);
    Q_INVOKABLE void updateQuantityByProductId(int productId, double quantity);
    
    // Obtener items como QVariantList para QML
    QVariantList itemsAsVariantList() const;

signals:
    void countChanged();
    void subtotalChanged();
    void totalChanged();
    void itemAdded(const QString& productName);
    void itemRemoved(const QString& productName);
    void quantityUpdated(int index);
    void error(const QString& message);

private:
    QList<SaleItem> m_items;
    QMap<int, double> m_maxQuantities;  // productId -> max stock

    void notifyTotalsChanged();
};

/**
 * @brief ViewModel para el proceso de ventas con carrito
 */
class SalesCartViewModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(CartItemModel* cart READ cart CONSTANT)
    Q_PROPERTY(bool isProcessing READ isProcessing NOTIFY isProcessingChanged)
    Q_PROPERTY(QString lastInvoiceNumber READ lastInvoiceNumber NOTIFY lastInvoiceNumberChanged)
    Q_PROPERTY(double discount READ discount WRITE setDiscount NOTIFY discountChanged)
    Q_PROPERTY(double totalWithDiscount READ totalWithDiscount NOTIFY totalWithDiscountChanged)
    Q_PROPERTY(bool canProcessSale READ canProcessSale NOTIFY canProcessSaleChanged)

public:
    explicit SalesCartViewModel(QObject *parent = nullptr);
    ~SalesCartViewModel();

    CartItemModel* cart() const { return m_cart; }
    bool isProcessing() const { return m_isProcessing; }
    QString lastInvoiceNumber() const { return m_lastInvoiceNumber; }
    double discount() const { return m_discount; }
    double totalWithDiscount() const;
    bool canProcessSale() const;
    
    void setDiscount(double discount);

public slots:
    /**
     * @brief Buscar producto por código de barras o SKU
     * @return true si se encontró y agregó al carrito
     */
    bool searchAndAddProduct(const QString& code, double quantity = 1.0);

    /**
     * @brief Buscar producto por ID y agregarlo al carrito
     */
    bool addProductById(int productId, double quantity = 1.0);

    /**
     * @brief Procesar la venta actual
     */
    bool processSale(int customerId, const QString& customerName,
                     int paymentMethodId, const QString& paymentMethodName,
                     double discount, const QString& notes);
    
    /**
     * @brief Procesar venta con datos de factura completos
     */
    Q_INVOKABLE bool processSaleWithInvoiceData(
        int customerId,
        const QString& customerName,
        int paymentMethodId,
        const QString& paymentMethodName,
        bool isInvoice,
        const QString& ruc,
        const QString& businessName,
        const QString& address
    );

    /**
     * @brief Cancelar y limpiar el carrito
     */
    void cancelSale();

    /**
     * @brief Obtener información de producto
     */
    QVariantMap getProductInfo(int productId);

signals:
    void isProcessingChanged();
    void lastInvoiceNumberChanged();
    void discountChanged();
    void totalWithDiscountChanged();
    void canProcessSaleChanged();
    void saleCompleted(const QString& invoiceNumber, double total, const QString& voucherType,
                      const QVariantList& items, double subtotal, double discount);
    void saleFailed(const QString& errorMessage);
    void productAdded(const QString& productName, double quantity);
    void productNotFound(const QString& code);
    void insufficientStock(const QString& productName, double available, double requested);

private:
    CartItemModel* m_cart;
    SalesService m_salesService;
    ProductService m_productService;
    bool m_isProcessing = false;
    QString m_lastInvoiceNumber;
    double m_discount = 0.0;

    void setIsProcessing(bool processing);
    bool validateStock(const Product& product, double quantity, QString& errorMsg);
};

#endif // SALESCARTVIEWMODEL_H
