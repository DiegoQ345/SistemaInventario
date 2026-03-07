#ifndef CUSTOMER_H
#define CUSTOMER_H

#include <QString>
#include <QDateTime>

/**
 * @brief Modelo de dominio para Cliente
 */
struct Customer
{
    int id = 0;
    QString name;
    QString documentType;  // DNI, RUC, CE, etc.
    QString documentNumber;
    QString email;
    QString phone;
    QString address;
    
    // Estadísticas de compras
    int totalPurchases = 0;
    double totalSpent = 0.0;
    QDateTime lastPurchaseDate;
    
    // Sistema de créditos
    double creditLimit = 0.0;   // Límite de crédito disponible
    double currentDebt = 0.0;    // Deuda actual
    
    QDateTime createdAt;
    QDateTime updatedAt;

    bool isValid() const {
        return !name.isEmpty();
    }

    QString displayName() const {
        if (!documentNumber.isEmpty()) {
            return QString("%1 (%2)").arg(name, documentNumber);
        }
        return name;
    }
    
    QString displayNameWithStats() const {
        if (totalPurchases > 0) {
            return QString("%1 - %2 compras - S/ %3")
                .arg(displayName())
                .arg(totalPurchases)
                .arg(totalSpent, 0, 'f', 2);
        }
        return displayName();
    }
    
    double availableCredit() const {
        return creditLimit - currentDebt;
    }
    
    bool hasDebt() const {
        return currentDebt > 0.0;
    }
};

#endif // CUSTOMER_H
