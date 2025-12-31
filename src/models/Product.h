#ifndef PRODUCT_H
#define PRODUCT_H

#include <QString>
#include <QDateTime>

/**
 * @brief Modelo de dominio para Producto
 * 
 * Representa un producto en el sistema de inventario.
 * Esta clase es un POJO (Plain Old C++ Object) sin lógica de negocio.
 */
struct Product
{
    int id = 0;
    QString name;
    QString sku;
    QString barcode;
    int categoryId = 0;
    QString categoryName;  // Para joins
    double currentStock = 0.0;
    double minimumStock = 0.0;
    double purchasePrice = 0.0;
    double salePrice = 0.0;
    QString description;
    QString imagePath;
    bool active = true;
    QDateTime createdAt;
    QDateTime updatedAt;

    /**
     * @brief Validar si el producto es válido
     */
    bool isValid() const {
        return !name.isEmpty() && salePrice >= 0;
    }

    /**
     * @brief Verificar si el stock está bajo
     */
    bool isLowStock() const {
        return currentStock <= minimumStock;
    }

    /**
     * @brief Calcular margen de ganancia (%)
     */
    double profitMargin() const {
        if (purchasePrice <= 0) return 0.0;
        return ((salePrice - purchasePrice) / purchasePrice) * 100.0;
    }
};

#endif // PRODUCT_H
