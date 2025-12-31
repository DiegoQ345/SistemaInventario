#ifndef STOCKMOVEMENT_H
#define STOCKMOVEMENT_H

#include <QString>
#include <QDateTime>

/**
 * @brief Modelo para movimientos de stock (Kardex)
 */
struct StockMovement
{
    int id = 0;
    int productId = 0;
    int movementTypeId = 0;
    QString movementTypeName;  // Para joins
    QString movementTypeCode;
    double quantity = 0.0;
    double previousStock = 0.0;
    double newStock = 0.0;
    double unitPrice = 0.0;
    QString reference;  // Nº de factura, orden, etc.
    QString notes;
    QDateTime createdAt;
    QString createdBy;

    bool isValid() const {
        return productId > 0 && movementTypeId > 0 && quantity != 0;
    }

    double totalValue() const {
        return quantity * unitPrice;
    }
};

#endif // STOCKMOVEMENT_H
