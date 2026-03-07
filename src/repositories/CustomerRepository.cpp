#include "CustomerRepository.h"
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDebug>

CustomerRepository::CustomerRepository(QSqlDatabase& db, QObject *parent)
    : QObject(parent), m_db(db)
{
}

std::optional<Customer> CustomerRepository::create(const Customer& customer)
{
    QSqlQuery query(m_db);
    query.prepare(
        "INSERT INTO customers (name, document_type, document_number, email, phone, address) "
        "VALUES (:name, :document_type, :document_number, :email, :phone, :address)"
    );
    
    query.bindValue(":name", customer.name);
    query.bindValue(":document_type", customer.documentType);
    query.bindValue(":document_number", customer.documentNumber);
    query.bindValue(":email", customer.email);
    query.bindValue(":phone", customer.phone);
    query.bindValue(":address", customer.address);

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qWarning() << "Error creating customer:" << m_lastError;
        return std::nullopt;
    }

    int newId = query.lastInsertId().toInt();
    return findById(newId);
}

std::optional<Customer> CustomerRepository::findById(int id)
{
    QSqlQuery query(m_db);
    query.prepare("SELECT * FROM customers WHERE id = :id");
    query.bindValue(":id", id);

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        return std::nullopt;
    }

    if (query.next()) {
        return mapFromQuery(query);
    }

    return std::nullopt;
}

QList<Customer> CustomerRepository::findAll()
{
    QList<Customer> customers;
    QSqlQuery query(m_db);

    if (!query.exec("SELECT * FROM customers ORDER BY name ASC")) {
        m_lastError = query.lastError().text();
        return customers;
    }

    while (query.next()) {
        customers.append(mapFromQuery(query));
    }

    return customers;
}

QList<Customer> CustomerRepository::search(const QString& searchTerm)
{
    QList<Customer> customers;
    QSqlQuery query(m_db);
    
    query.prepare(
        "SELECT * FROM customers WHERE "
        "name LIKE :search OR "
        "document_number LIKE :search OR "
        "email LIKE :search OR "
        "phone LIKE :search "
        "ORDER BY name ASC"
    );
    
    QString pattern = "%" + searchTerm + "%";
    query.bindValue(":search", pattern);

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        return customers;
    }

    while (query.next()) {
        customers.append(mapFromQuery(query));
    }

    return customers;
}

bool CustomerRepository::update(const Customer& customer)
{
    QSqlQuery query(m_db);
    query.prepare(
        "UPDATE customers SET "
        "name = :name, "
        "document_type = :document_type, "
        "document_number = :document_number, "
        "email = :email, "
        "phone = :phone, "
        "address = :address, "
        "credit_limit = :credit_limit, "
        "updated_at = datetime('now') "
        "WHERE id = :id"
    );

    query.bindValue(":id", customer.id);
    query.bindValue(":name", customer.name);
    query.bindValue(":document_type", customer.documentType);
    query.bindValue(":document_number", customer.documentNumber);
    query.bindValue(":email", customer.email);
    query.bindValue(":phone", customer.phone);
    query.bindValue(":address", customer.address);
    query.bindValue(":credit_limit", customer.creditLimit);

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qWarning() << "Error updating customer:" << m_lastError;
        return false;
    }

    return query.numRowsAffected() > 0;
}

bool CustomerRepository::deleteById(int id)
{
    QSqlQuery query(m_db);
    query.prepare("DELETE FROM customers WHERE id = :id");
    query.bindValue(":id", id);

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qWarning() << "Error deleting customer:" << m_lastError;
        return false;
    }

    return query.numRowsAffected() > 0;
}

QList<Customer> CustomerRepository::findTopCustomers(int limit)
{
    QList<Customer> customers;
    QSqlQuery query(m_db);
    
    query.prepare(
        "SELECT c.*, COUNT(s.id) as purchase_count, SUM(s.total) as total_spent "
        "FROM customers c "
        "LEFT JOIN sales s ON c.id = s.customer_id "
        "GROUP BY c.id "
        "ORDER BY total_spent DESC "
        "LIMIT :limit"
    );
    
    query.bindValue(":limit", limit);

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        return customers;
    }

    while (query.next()) {
        customers.append(mapFromQuery(query));
    }

    return customers;
}

int CustomerRepository::getTotalCustomers()
{
    QSqlQuery query(m_db);
    
    if (!query.exec("SELECT COUNT(*) FROM customers")) {
        m_lastError = query.lastError().text();
        return 0;
    }

    if (query.next()) {
        return query.value(0).toInt();
    }

    return 0;
}

QList<Customer> CustomerRepository::findByDocumentNumber(const QString& documentNumber)
{
    QList<Customer> customers;
    QSqlQuery query(m_db);
    
    query.prepare("SELECT * FROM customers WHERE document_number = :document_number");
    query.bindValue(":document_number", documentNumber);

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        return customers;
    }

    while (query.next()) {
        customers.append(mapFromQuery(query));
    }

    return customers;
}

bool CustomerRepository::updatePurchaseStats(int customerId, double saleTotal)
{
    QSqlQuery query(m_db);
    query.prepare(
        "UPDATE customers SET "
        "total_purchases = total_purchases + 1, "
        "total_spent = total_spent + :sale_total, "
        "last_purchase_date = datetime('now'), "
        "updated_at = datetime('now') "
        "WHERE id = :id"
    );
    
    query.bindValue(":id", customerId);
    query.bindValue(":sale_total", saleTotal);

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qWarning() << "Error updating customer purchase stats:" << m_lastError;
        return false;
    }

    return query.numRowsAffected() > 0;
}

Customer CustomerRepository::mapFromQuery(const QSqlQuery& query) const
{
    Customer customer;
    customer.id = query.value("id").toInt();
    customer.name = query.value("name").toString();
    customer.documentType = query.value("document_type").toString();
    customer.documentNumber = query.value("document_number").toString();
    customer.email = query.value("email").toString();
    customer.phone = query.value("phone").toString();
    customer.address = query.value("address").toString();
    
    // Estadísticas de compras
    customer.totalPurchases = query.value("total_purchases").toInt();
    customer.totalSpent = query.value("total_spent").toDouble();
    if (!query.value("last_purchase_date").isNull()) {
        customer.lastPurchaseDate = QDateTime::fromString(query.value("last_purchase_date").toString(), Qt::ISODate);
    }
    
    // Sistema de créditos
    customer.creditLimit = query.value("credit_limit").toDouble();
    customer.currentDebt = query.value("current_debt").toDouble();
    
    customer.createdAt = QDateTime::fromString(query.value("created_at").toString(), Qt::ISODate);
    customer.updatedAt = QDateTime::fromString(query.value("updated_at").toString(), Qt::ISODate);
    return customer;
}

bool CustomerRepository::updateDebt(int customerId, double amount, bool add)
{
    QSqlQuery query(m_db);
    
    if (add) {
        // Agregar a la deuda (venta a crédito)
        query.prepare(
            "UPDATE customers SET "
            "current_debt = current_debt + :amount, "
            "updated_at = datetime('now') "
            "WHERE id = :id"
        );
    } else {
        // Reducir la deuda (pago)
        query.prepare(
            "UPDATE customers SET "
            "current_debt = MAX(0, current_debt - :amount), "
            "updated_at = datetime('now') "
            "WHERE id = :id"
        );
    }
    
    query.bindValue(":id", customerId);
    query.bindValue(":amount", amount);

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qWarning() << "Error updating customer debt:" << m_lastError;
        return false;
    }

    return query.numRowsAffected() > 0;
}

bool CustomerRepository::setCreditLimit(int customerId, double limit)
{
    QSqlQuery query(m_db);
    
    query.prepare(
        "UPDATE customers SET "
        "credit_limit = :limit, "
        "updated_at = datetime('now') "
        "WHERE id = :id"
    );
    
    query.bindValue(":id", customerId);
    query.bindValue(":limit", limit);

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qWarning() << "Error setting credit limit:" << m_lastError;
        return false;
    }

    return query.numRowsAffected() > 0;
}

double CustomerRepository::getCurrentDebt(int customerId)
{
    QSqlQuery query(m_db);
    
    query.prepare("SELECT current_debt FROM customers WHERE id = :id");
    query.bindValue(":id", customerId);

    if (query.exec() && query.next()) {
        return query.value(0).toDouble();
    }
    
    m_lastError = query.lastError().text();
    return 0.0;
}

double CustomerRepository::getAvailableCredit(int customerId)
{
    QSqlQuery query(m_db);
    
    query.prepare("SELECT credit_limit, current_debt FROM customers WHERE id = :id");
    query.bindValue(":id", customerId);

    if (query.exec() && query.next()) {
        double creditLimit = query.value(0).toDouble();
        double currentDebt = query.value(1).toDouble();
        return creditLimit - currentDebt;
    }
    
    m_lastError = query.lastError().text();
    return 0.0;
}

