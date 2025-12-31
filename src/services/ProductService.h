#ifndef PRODUCTSERVICE_H
#define PRODUCTSERVICE_H

#include "../models/Product.h"
#include "../models/StockMovement.h"
#include "../repositories/ProductRepository.h"
#include <QObject>
#include <QList>
#include <optional>

/**
 * @brief Servicio de negocio para gestión de productos
 * 
 * Encapsula lógica de negocio y coordina repositorios.
 * Thread-safe mediante uso de señales Qt.
 */
class ProductService : public QObject
{
    Q_OBJECT

public:
    explicit ProductService(QObject *parent = nullptr);

    /**
     * @brief Crear producto con validaciones
     */
    bool createProduct(Product& product, QString& errorMessage);

    /**
     * @brief Actualizar producto
     */
    bool updateProduct(const Product& product, QString& errorMessage);

    /**
     * @brief Eliminar producto
     */
    bool deleteProduct(int productId, QString& errorMessage);

    /**
     * @brief Buscar producto
     */
    std::optional<Product> getProduct(int productId);
    std::optional<Product> getProductBySku(const QString& sku);
    std::optional<Product> getProductByBarcode(const QString& barcode);

    /**
     * @brief Listar productos
     */
    QList<Product> getAllProducts(bool activeOnly = true);
    QList<Product> searchProducts(const QString& searchTerm);
    QList<Product> getProductsByCategory(int categoryId);
    QList<Product> getLowStockProducts();

    /**
     * @brief Movimientos de stock
     */
    bool registerStockMovement(int productId, const QString& movementTypeCode,
                              double quantity, double unitPrice,
                              const QString& reference, const QString& notes,
                              QString& errorMessage);

    /**
     * @brief Ajustar stock directamente
     */
    bool adjustStock(int productId, double newStock, const QString& reason, QString& errorMessage);

    /**
     * @brief Obtener historial de movimientos (Kardex)
     */
    QList<StockMovement> getStockHistory(int productId);

    /**
     * @brief Validar SKU único
     */
    bool isSkuUnique(const QString& sku, int excludeProductId = 0);

    /**
     * @brief Validar código de barras único
     */
    bool isBarcodeUnique(const QString& barcode, int excludeProductId = 0);

signals:
    /**
     * @brief Emitido cuando se crea un producto
     */
    void productCreated(int productId);

    /**
     * @brief Emitido cuando se actualiza un producto
     */
    void productUpdated(int productId);

    /**
     * @brief Emitido cuando se elimina un producto
     */
    void productDeleted(int productId);

    /**
     * @brief Emitido cuando el stock cambia
     */
    void stockChanged(int productId, double oldStock, double newStock);

    /**
     * @brief Alerta de stock bajo
     */
    void lowStockAlert(int productId, const QString& productName, double currentStock);

private:
    ProductRepository m_productRepo;

    /**
     * @brief Validar datos del producto
     */
    bool validateProduct(const Product& product, QString& errorMessage);

    /**
     * @brief Verificar y emitir alerta de stock bajo
     */
    void checkLowStock(const Product& product);

    /**
     * @brief Registrar movimiento en el kardex
     */
    bool logStockMovement(int productId, int movementTypeId, double quantity,
                         double previousStock, double newStock, double unitPrice,
                         const QString& reference, const QString& notes);

    /**
     * @brief Obtener ID de tipo de movimiento por código
     */
    int getMovementTypeId(const QString& code);
};

#endif // PRODUCTSERVICE_H
