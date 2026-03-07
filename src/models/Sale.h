#ifndef SALE_H
#define SALE_H

#include <QString>
#include <QDateTime>
#include <QList>

/**
 * @brief Item individual de una venta
 */
struct SaleItem
{
    int id = 0;
    int saleId = 0;
    int productId = 0;
    QString productName;  // Snapshot
    double quantity = 0.0;
    double unitPrice = 0.0;
    double subtotal = 0.0;

    void calculateSubtotal() {
        subtotal = quantity * unitPrice;
    }
};

/**
 * @brief Modelo de dominio para Venta
 */
struct Sale
{
    int id = 0;
    QString invoiceNumber;
    QString voucherType = "TICKET";  // BOLETA, FACTURA, TICKET
    int customerId = 0;
    QString customerName;  // Para joins
    
    // Campos de facturación (para FACTURA)
    QString customerRuc;
    QString customerBusinessName;  // Razón social
    QString customerAddress;
    
    double subtotal = 0.0;
    double tax = 0.0;
    double discount = 0.0;
    double total = 0.0;
    int paymentMethodId = 0;
    QString paymentMethodName;  // Para joins
    
    // Sistema de créditos
    QString paymentType = "CONTADO";  // CONTADO o CREDITO
    QString paymentStatus = "PAID";   // PAID, PENDING, PARTIAL
    
    QString status = "COMPLETED";  // COMPLETED, CANCELLED, PENDING
    QString notes;
    QDateTime createdAt;
    QString createdBy;

    QList<SaleItem> items;  // Items de la venta

    /**
     * @brief Calcular totales de la venta
     */
    void calculateTotals() {
        subtotal = 0.0;
        for (const auto& item : items) {
            subtotal += item.subtotal;
        }
        total = subtotal + tax - discount;
    }

    bool isValid() const {
        return !invoiceNumber.isEmpty() && !items.isEmpty() && total > 0;
    }

    int itemCount() const {
        return items.size();
    }

    double totalQuantity() const {
        double sum = 0.0;
        for (const auto& item : items) {
            sum += item.quantity;
        }
        return sum;
    }
    
    bool isCredit() const {
        return paymentType == "CREDITO";
    }
    
    bool isPending() const {
        return paymentStatus == "PENDING" || paymentStatus == "PARTIAL";
    }
};

#endif // SALE_H
