#include "SaleRepository.h"
#include "../database/DatabaseManager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDebug>

int SaleRepository::create(Sale& sale)
{
    auto& db = DatabaseManager::instance();
    
    // Iniciar transacción
    if (!db.beginTransaction()) {
        qCritical() << "Error iniciando transacción para venta";
        return 0;
    }

    QSqlQuery query(db.database());
    
    // Insertar venta principal
    query.prepare(
        "INSERT INTO sales (invoice_number, customer_id, subtotal, tax, discount, total, "
        "payment_method_id, status, notes, created_by) "
        "VALUES (:invoice_number, :customer_id, :subtotal, :tax, :discount, :total, "
        ":payment_method_id, :status, :notes, :created_by)"
    );

    query.bindValue(":invoice_number", sale.invoiceNumber);
    query.bindValue(":customer_id", sale.customerId > 0 ? sale.customerId : QVariant());
    query.bindValue(":subtotal", sale.subtotal);
    query.bindValue(":tax", sale.tax);
    query.bindValue(":discount", sale.discount);
    query.bindValue(":total", sale.total);
    query.bindValue(":payment_method_id", sale.paymentMethodId > 0 ? sale.paymentMethodId : QVariant());
    query.bindValue(":status", sale.status);
    query.bindValue(":notes", sale.notes);
    query.bindValue(":created_by", sale.createdBy);

    if (!query.exec()) {
        qCritical() << "Error creando venta:" << query.lastError().text();
        db.rollback();
        return 0;
    }

    int saleId = query.lastInsertId().toInt();
    sale.id = saleId;

    // Insertar items de venta
    query.prepare(
        "INSERT INTO sale_items (sale_id, product_id, product_name, quantity, unit_price, subtotal) "
        "VALUES (:sale_id, :product_id, :product_name, :quantity, :unit_price, :subtotal)"
    );

    for (auto& item : sale.items) {
        query.bindValue(":sale_id", saleId);
        query.bindValue(":product_id", item.productId);
        query.bindValue(":product_name", item.productName);
        query.bindValue(":quantity", item.quantity);
        query.bindValue(":unit_price", item.unitPrice);
        query.bindValue(":subtotal", item.subtotal);

        if (!query.exec()) {
            qCritical() << "Error insertando item de venta:" << query.lastError().text();
            db.rollback();
            return 0;
        }

        item.id = query.lastInsertId().toInt();
        item.saleId = saleId;
    }

    // Confirmar transacción
    if (!db.commit()) {
        qCritical() << "Error confirmando transacción de venta";
        db.rollback();
        return 0;
    }

    return saleId;
}

std::optional<Sale> SaleRepository::findById(int id)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare(
        "SELECT s.*, c.name as customer_name, pm.name as payment_method_name "
        "FROM sales s "
        "LEFT JOIN customers c ON s.customer_id = c.id "
        "LEFT JOIN payment_methods pm ON s.payment_method_id = pm.id "
        "WHERE s.id = :id"
    );
    query.bindValue(":id", id);

    if (!query.exec()) {
        qCritical() << "Error buscando venta:" << query.lastError().text();
        return std::nullopt;
    }

    if (query.next()) {
        Sale sale = mapFromQuery(query);
        sale.items = loadSaleItems(id);
        return sale;
    }

    return std::nullopt;
}

std::optional<Sale> SaleRepository::findByInvoiceNumber(const QString& invoiceNumber)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare(
        "SELECT s.*, c.name as customer_name, pm.name as payment_method_name "
        "FROM sales s "
        "LEFT JOIN customers c ON s.customer_id = c.id "
        "LEFT JOIN payment_methods pm ON s.payment_method_id = pm.id "
        "WHERE s.invoice_number = :invoice_number"
    );
    query.bindValue(":invoice_number", invoiceNumber);

    if (!query.exec()) {
        qCritical() << "Error buscando venta:" << query.lastError().text();
        return std::nullopt;
    }

    if (query.next()) {
        Sale sale = mapFromQuery(query);
        sale.items = loadSaleItems(sale.id);
        return sale;
    }

    return std::nullopt;
}

QList<Sale> SaleRepository::findByDateRange(const QDate& from, const QDate& to)
{
    QList<Sale> sales;
    QSqlQuery query(DatabaseManager::instance().database());
    
    query.prepare(
        "SELECT s.*, c.name as customer_name, pm.name as payment_method_name "
        "FROM sales s "
        "LEFT JOIN customers c ON s.customer_id = c.id "
        "LEFT JOIN payment_methods pm ON s.payment_method_id = pm.id "
        "WHERE DATE(s.created_at) BETWEEN :from AND :to "
        "ORDER BY s.created_at DESC"
    );
    query.bindValue(":from", from.toString(Qt::ISODate));
    query.bindValue(":to", to.toString(Qt::ISODate));

    if (!query.exec()) {
        qCritical() << "Error obteniendo ventas:" << query.lastError().text();
        return sales;
    }

    while (query.next()) {
        Sale sale = mapFromQuery(query);
        sale.items = loadSaleItems(sale.id);
        sales.append(sale);
    }

    return sales;
}

QList<Sale> SaleRepository::findToday()
{
    QDate today = QDate::currentDate();
    return findByDateRange(today, today);
}

bool SaleRepository::cancel(int saleId)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare("UPDATE sales SET status = 'CANCELLED' WHERE id = :id");
    query.bindValue(":id", saleId);
    
    if (!query.exec()) {
        qCritical() << "Error cancelando venta:" << query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}

QString SaleRepository::generateNextInvoiceNumber()
{
    QSqlQuery query(DatabaseManager::instance().database());
    
    // Obtener el último número de factura del día
    query.prepare(
        "SELECT invoice_number FROM sales "
        "WHERE DATE(created_at) = DATE('now') "
        "ORDER BY id DESC LIMIT 1"
    );

    if (!query.exec()) {
        qCritical() << "Error generando número de factura:" << query.lastError().text();
    }

    QString prefix = QDate::currentDate().toString("yyyyMMdd");
    int sequence = 1;

    if (query.next()) {
        QString lastInvoice = query.value(0).toString();
        // Formato: YYYYMMDD-XXXX
        QStringList parts = lastInvoice.split('-');
        if (parts.size() == 2 && parts[0] == prefix) {
            sequence = parts[1].toInt() + 1;
        }
    }

    return QString("%1-%2").arg(prefix).arg(sequence, 4, 10, QChar('0'));
}

SaleRepository::SalesStats SaleRepository::getStatsForDate(const QDate& date)
{
    return getStatsForDateRange(date, date);
}

SaleRepository::SalesStats SaleRepository::getStatsForDateRange(const QDate& from, const QDate& to)
{
    SalesStats stats;
    QSqlQuery query(DatabaseManager::instance().database());
    
    query.prepare(
        "SELECT COUNT(*) as count, COALESCE(SUM(total), 0) as total "
        "FROM sales "
        "WHERE DATE(created_at) BETWEEN :from AND :to AND status = 'COMPLETED'"
    );
    query.bindValue(":from", from.toString(Qt::ISODate));
    query.bindValue(":to", to.toString(Qt::ISODate));

    if (query.exec() && query.next()) {
        stats.totalTransactions = query.value("count").toInt();
        stats.totalSales = query.value("total").toDouble();
        
        if (stats.totalTransactions > 0) {
            stats.averageTicket = stats.totalSales / stats.totalTransactions;
        }
    }

    return stats;
}

Sale SaleRepository::mapFromQuery(const QSqlQuery& query)
{
    Sale sale;
    sale.id = query.value("id").toInt();
    sale.invoiceNumber = query.value("invoice_number").toString();
    sale.customerId = query.value("customer_id").toInt();
    sale.customerName = query.value("customer_name").toString();
    sale.subtotal = query.value("subtotal").toDouble();
    sale.tax = query.value("tax").toDouble();
    sale.discount = query.value("discount").toDouble();
    sale.total = query.value("total").toDouble();
    sale.paymentMethodId = query.value("payment_method_id").toInt();
    sale.paymentMethodName = query.value("payment_method_name").toString();
    sale.status = query.value("status").toString();
    sale.notes = query.value("notes").toString();
    sale.createdAt = QDateTime::fromString(query.value("created_at").toString(), Qt::ISODate);
    sale.createdBy = query.value("created_by").toString();
    return sale;
}

QList<SaleItem> SaleRepository::loadSaleItems(int saleId)
{
    QList<SaleItem> items;
    QSqlQuery query(DatabaseManager::instance().database());
    
    query.prepare(
        "SELECT * FROM sale_items WHERE sale_id = :sale_id ORDER BY id"
    );
    query.bindValue(":sale_id", saleId);

    if (!query.exec()) {
        qCritical() << "Error cargando items de venta:" << query.lastError().text();
        return items;
    }

    while (query.next()) {
        SaleItem item;
        item.id = query.value("id").toInt();
        item.saleId = query.value("sale_id").toInt();
        item.productId = query.value("product_id").toInt();
        item.productName = query.value("product_name").toString();
        item.quantity = query.value("quantity").toDouble();
        item.unitPrice = query.value("unit_price").toDouble();
        item.subtotal = query.value("subtotal").toDouble();
        items.append(item);
    }

    return items;
}
