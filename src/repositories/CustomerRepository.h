#ifndef CUSTOMERREPOSITORY_H
#define CUSTOMERREPOSITORY_H

#include "../models/Customer.h"
#include <QObject>
#include <QString>
#include <QList>
#include <QSqlQuery>
#include <optional>

class QSqlDatabase;

/**
 * @brief Repositorio para acceso a datos de clientes
 */
class CustomerRepository : public QObject
{
    Q_OBJECT
public:
    explicit CustomerRepository(QSqlDatabase& db, QObject *parent = nullptr);

    // CRUD Operations
    std::optional<Customer> create(const Customer& customer);
    std::optional<Customer> findById(int id);
    QList<Customer> findAll();
    QList<Customer> search(const QString& searchTerm);
    bool update(const Customer& customer);
    bool deleteById(int id);

    // Business queries
    QList<Customer> findTopCustomers(int limit = 10);
    int getTotalCustomers();
    QList<Customer> findByDocumentNumber(const QString& documentNumber);
    
    // Purchase statistics
    bool updatePurchaseStats(int customerId, double saleTotal);
    
    // Credit management
    bool updateDebt(int customerId, double amount, bool add = true);
    bool setCreditLimit(int customerId, double limit);
    double getCurrentDebt(int customerId);
    double getAvailableCredit(int customerId);

    QString lastError() const { return m_lastError; }

private:
    QSqlDatabase& m_db;
    QString m_lastError;

    Customer mapFromQuery(const QSqlQuery& query) const;
};

#endif // CUSTOMERREPOSITORY_H
