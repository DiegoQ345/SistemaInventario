#ifndef PRODUCTREPOSITORY_H
#define PRODUCTREPOSITORY_H

#include "../models/Product.h"
#include <QList>
#include <QString>
#include <optional>

/**
 * @brief Repositorio para acceso a datos de Productos
 * 
 * Patrón Repository: encapsula toda la lógica de acceso a datos.
 * Permite cambiar la implementación de persistencia sin afectar
 * a las capas superiores.
 */
class ProductRepository
{
public:
    ProductRepository() = default;

    /**
     * @brief Crear un nuevo producto
     * @return ID del producto creado, o 0 si falla
     */
    int create(Product& product);

    /**
     * @brief Actualizar producto existente
     */
    bool update(const Product& product);

    /**
     * @brief Eliminar producto (soft delete)
     */
    bool remove(int id);

    /**
     * @brief Buscar producto por ID
     */
    std::optional<Product> findById(int id);

    /**
     * @brief Buscar producto por SKU
     */
    std::optional<Product> findBySku(const QString& sku);

    /**
     * @brief Buscar producto por código de barras
     */
    std::optional<Product> findByBarcode(const QString& barcode);

    /**
     * @brief Obtener todos los productos activos
     */
    QList<Product> findAll(bool activeOnly = true);

    /**
     * @brief Buscar productos por nombre (búsqueda parcial)
     */
    QList<Product> searchByName(const QString& name);

    /**
     * @brief Obtener productos por categoría
     */
    QList<Product> findByCategory(int categoryId);

    /**
     * @brief Obtener productos con stock bajo
     */
    QList<Product> findLowStock();

    /**
     * @brief Actualizar stock de un producto
     * @param productId ID del producto
     * @param newStock Nuevo valor de stock
     * @return true si se actualizó correctamente
     */
    bool updateStock(int productId, double newStock);

    /**
     * @brief Contar total de productos
     */
    int count();

private:
    /**
     * @brief Mapear un QSqlQuery a un objeto Product
     */
    Product mapFromQuery(const class QSqlQuery& query);
};

#endif // PRODUCTREPOSITORY_H
