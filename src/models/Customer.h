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
};

#endif // CUSTOMER_H
