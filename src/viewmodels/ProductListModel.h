#ifndef PRODUCTLISTMODEL_H
#define PRODUCTLISTMODEL_H

#include "../models/Product.h"
#include <QAbstractListModel>
#include <QList>
#include <qqml.h>

/**
 * @brief Modelo de lista de productos para QML
 * 
 * Expone lista de productos como un QAbstractListModel
 * para usar en ListView, GridView, etc.
 */
class ProductListModel : public QAbstractListModel
{
    Q_OBJECT
    // QML_ELEMENT - Registrado manualmente en main.cpp

    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(QStringList availableCategories READ availableCategories NOTIFY availableCategoriesChanged)
    Q_PROPERTY(bool isExporting READ isExporting NOTIFY isExportingChanged)
    Q_PROPERTY(int exportProgress READ exportProgress NOTIFY exportProgressChanged)
    Q_PROPERTY(QString exportProgressMessage READ exportProgressMessage NOTIFY exportProgressMessageChanged)

public:
    enum ProductRoles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        SkuRole,
        BarcodeRole,
        CategoryRole,
        CurrentStockRole,
        MinimumStockRole,
        PurchasePriceRole,
        SalePriceRole,
        DescriptionRole,
        ActiveRole,
        IsLowStockRole
    };

    explicit ProductListModel(QObject *parent = nullptr);

    // Implementación de QAbstractListModel
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    bool isLoading() const { return m_isLoading; }
    QStringList availableCategories() const { return m_availableCategories; }
    bool isExporting() const { return m_isExporting; }
    int exportProgress() const { return m_exportProgress; }
    QString exportProgressMessage() const { return m_exportProgressMessage; }

public slots:
    /**
     * @brief Cargar todos los productos
     */
    void loadProducts();

    /**
     * @brief Buscar productos por nombre
     */
    void searchProducts(const QString& searchTerm);

    /**
     * @brief Filtrar por categoría
     */
    void filterByCategory(int categoryId);

    /**
     * @brief Filtrar por nombre de categoría
     */
    Q_INVOKABLE void filterByCategoryName(const QString& categoryName);

    /**
     * @brief Obtener todas las categorías disponibles desde la BD
     */
    Q_INVOKABLE QStringList getAvailableCategories();
    
    /**
     * @brief Recargar las categorías desde la BD
     */
    Q_INVOKABLE void loadAvailableCategories();

    /**
     * @brief Filtrar productos con stock bajo
     */
    void filterLowStock();

    /**
     * @brief Obtener producto por índice
     */
    Q_INVOKABLE QVariantMap getProduct(int index) const;

    /**
     * @brief Agregar nuevo producto
     */
    Q_INVOKABLE bool addProduct(const QVariantMap& productData);

    /**
     * @brief Actualizar producto existente
     */
    Q_INVOKABLE bool updateProduct(int productId, const QVariantMap& productData);

    /**
     * @brief Eliminar producto
     */
    Q_INVOKABLE bool deleteProduct(int productId);
    
    /**
     * @brief Eliminar TODOS los productos
     */
    Q_INVOKABLE bool deleteAllProducts();
    
    /**
     * @brief Reponer inventario (incrementar stock)
     * @param productId ID del producto
     * @param quantity Cantidad a agregar al stock actual
     * @return true si se actualizó correctamente
     */
    Q_INVOKABLE bool restockProduct(int productId, double quantity);

    /**
     * @brief Validar datos del producto antes de guardar
     */
    Q_INVOKABLE QString validateProductData(const QVariantMap& productData) const;

    /**
     * @brief Obtener datos del producto para edición por ID
     */
    Q_INVOKABLE QVariantMap getProductForEdit(int productId) const;

    /**
     * @brief Verificar si existe un producto con el código de barras dado
     */
    Q_INVOKABLE bool hasProductWithBarcode(const QString& barcode) const;
    
    /**
     * @brief Exportar inventario completo a Excel
     * @return true si la exportación se inició correctamente
     */
    Q_INVOKABLE bool exportToExcel();

signals:
    void countChanged();
    void isLoadingChanged();
    void availableCategoriesChanged();
    void errorOccurred(const QString& message);
    void productAdded(int productId);
    void productUpdated(int productId);
    void productDeleted(int productId);
    void operationSucceeded(const QString& message);
    void isExportingChanged();
    void exportProgressChanged();
    void exportProgressMessageChanged();
    void exportCompleted(bool success, const QString& filePath);

private:
    QList<Product> m_products;
    bool m_isLoading = false;
    QStringList m_availableCategories;
    bool m_isExporting = false;
    int m_exportProgress = 0;
    QString m_exportProgressMessage;

    void setIsLoading(bool loading);
    void setIsExporting(bool exporting);
    void setExportProgress(int progress);
    void setExportProgressMessage(const QString& message);
    QVariantMap productToVariantMap(const Product& product) const;
};

#endif // PRODUCTLISTMODEL_H
