#include "SaleRepository.h"
#include "../database/DatabaseManager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDebug>

int SaleRepository::create(Sale& sale)
{
    auto& db = DatabaseManager::instance();
    
    // NO iniciar transacción aquí - la maneja SalesService
    // El servicio ya inició la transacción antes de llamar a este método
    
    QSqlQuery query(db.database());
    
    // Insertar venta principal
    query.prepare(
        "INSERT INTO sales (invoice_number, voucher_type, customer_id, customer_name, "
        "customer_ruc, customer_business_name, customer_address, "
        "subtotal, tax, discount, total, payment_method_id, payment_type, payment_status, "
        "amount_paid, change_given, "
        "status, notes, created_by) "
        "VALUES (:invoice_number, :voucher_type, :customer_id, :customer_name, "
        ":customer_ruc, :customer_business_name, :customer_address, "
        ":subtotal, :tax, :discount, :total, :payment_method_id, :payment_type, :payment_status, "
        ":amount_paid, :change_given, "
        ":status, :notes, :created_by)"
    );

    query.bindValue(":invoice_number", sale.invoiceNumber);
    query.bindValue(":voucher_type", sale.voucherType);
    query.bindValue(":customer_id", sale.customerId > 0 ? sale.customerId : QVariant());
    query.bindValue(":customer_name", sale.customerName);
    query.bindValue(":customer_ruc", sale.customerRuc);
    query.bindValue(":customer_business_name", sale.customerBusinessName);
    query.bindValue(":customer_address", sale.customerAddress);
    query.bindValue(":subtotal", sale.subtotal);
    query.bindValue(":tax", sale.tax);
    query.bindValue(":discount", sale.discount);
    query.bindValue(":total", sale.total);
    query.bindValue(":payment_method_id", sale.paymentMethodId > 0 ? sale.paymentMethodId : QVariant());
    query.bindValue(":payment_type", sale.paymentType);
    query.bindValue(":payment_status", sale.paymentStatus);
    query.bindValue(":amount_paid", sale.amountPaid);
    query.bindValue(":change_given", sale.changeGiven);
    query.bindValue(":status", sale.status);
    query.bindValue(":notes", sale.notes);
    query.bindValue(":created_by", sale.createdBy);

    if (!query.exec()) {
        qCritical() << "Error creando venta:" << query.lastError().text();
        qCritical() << "  Invoice:" << sale.invoiceNumber;
        qCritical() << "  Customer ID:" << sale.customerId;
        qCritical() << "  Payment Method ID:" << sale.paymentMethodId;
        qCritical() << "  Total:" << sale.total;
        return 0;
    }

    int saleId = query.lastInsertId().toInt();
    sale.id = saleId;
    
    qDebug() << "  Sale inserted with ID:" << saleId;

    // Insertar items de venta
    query.prepare(
        "INSERT INTO sale_items (sale_id, product_id, product_name, quantity, unit_price, subtotal) "
        "VALUES (:sale_id, :product_id, :product_name, :quantity, :unit_price, :subtotal)"
    );

    int totalItemCount = 0;
    QStringList productNames;

    for (auto& item : sale.items) {
        query.bindValue(":sale_id", saleId);
        query.bindValue(":product_id", item.productId);
        query.bindValue(":product_name", item.productName);
        query.bindValue(":quantity", item.quantity);
        query.bindValue(":unit_price", item.unitPrice);
        query.bindValue(":subtotal", item.subtotal);

        if (!query.exec()) {
            qCritical() << "Error insertando item de venta:" << query.lastError().text();
            qCritical() << "  Product:" << item.productName;
            qCritical() << "  Quantity:" << item.quantity;
            return 0;
        }

        item.id = query.lastInsertId().toInt();
        item.saleId = saleId;
        
        // Acumular información para el resumen
        totalItemCount += static_cast<int>(item.quantity);
        if (!productNames.contains(item.productName)) {
            productNames << item.productName;
        }
    }
    
    qDebug() << "  " << sale.items.count() << "items inserted";

    // Actualizar la venta con el resumen de productos
    query.prepare(
        "UPDATE sales SET item_count = :item_count, product_names = :product_names WHERE id = :sale_id"
    );
    query.bindValue(":item_count", totalItemCount);
    query.bindValue(":product_names", productNames.join(", "));
    query.bindValue(":sale_id", saleId);

    if (!query.exec()) {
        qWarning() << "Error actualizando resumen de productos de venta:" << query.lastError().text();
        // No es crítico, continuamos
    } else {
        qDebug() << "  Sale summary updated: " << totalItemCount << " items, products: " << productNames.join(", ");
    }

    // NO confirmar transacción aquí - la maneja SalesService
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

QList<Sale> SaleRepository::findByCustomerId(int customerId)
{
    QList<Sale> sales;
    QSqlQuery query(DatabaseManager::instance().database());
    
    query.prepare(
        "SELECT s.*, c.name as customer_name, pm.name as payment_method_name "
        "FROM sales s "
        "LEFT JOIN customers c ON s.customer_id = c.id "
        "LEFT JOIN payment_methods pm ON s.payment_method_id = pm.id "
        "WHERE s.customer_id = :customer_id AND s.status = 'COMPLETED' "
        "ORDER BY s.created_at DESC"
    );
    query.bindValue(":customer_id", customerId);
    
    if (!query.exec()) {
        qCritical() << "Error obteniendo ventas por cliente:" << query.lastError().text();
        return sales;
    }

    while (query.next()) {
        Sale sale = mapFromQuery(query);
        sale.items = loadSaleItems(sale.id);
        sales.append(sale);
    }

    return sales;
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

bool SaleRepository::markAsPaid(int saleId)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare("UPDATE sales SET payment_status = 'PAID' WHERE id = :id");
    query.bindValue(":id", saleId);
    
    if (!query.exec()) {
        qCritical() << "Error marcando venta como pagada:" << query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}

int SaleRepository::markCustomerDebtsAsPaid(int customerId)
{
    auto& db = DatabaseManager::instance();
    QSqlDatabase database = db.database();
    
    // Iniciar transacción
    if (!database.transaction()) {
        qCritical() << "Error iniciando transacción para pagar deudas";
        return 0;
    }
    
    QSqlQuery query(database);
    
    // 1. Actualizar estado de ventas a PAID
    query.prepare(
        "UPDATE sales SET payment_status = 'PAID' "
        "WHERE customer_id = :customer_id "
        "AND payment_status IN ('PENDING', 'PARTIAL') "
        "AND status = 'COMPLETED'"
    );
    query.bindValue(":customer_id", customerId);
    
    if (!query.exec()) {
        qCritical() << "Error marcando deudas del cliente como pagadas:" << query.lastError().text();
        database.rollback();
        return 0;
    }

    int rowsUpdated = query.numRowsAffected();
    qDebug() << "Deudas pagadas del cliente" << customerId << ":" << rowsUpdated << "ventas actualizadas";
    
    // 2. Actualizar current_debt del cliente a 0
    QSqlQuery updateCustomerQuery(database);
    updateCustomerQuery.prepare(
        "UPDATE customers SET current_debt = 0 WHERE id = :customer_id"
    );
    updateCustomerQuery.bindValue(":customer_id", customerId);
    
    if (!updateCustomerQuery.exec()) {
        qCritical() << "Error actualizando deuda del cliente:" << updateCustomerQuery.lastError().text();
        database.rollback();
        return 0;
    }
    
    qDebug() << "Deuda del cliente actualizada a 0";
    
    // Confirmar transacción
    if (!database.commit()) {
        qCritical() << "Error confirmando transacción de pago de deudas";
        database.rollback();
        return 0;
    }
    
    qDebug() << "Transacción de pago completada exitosamente";
    
    return rowsUpdated;
}

bool SaleRepository::markSaleAsPaid(int saleId)
{
    auto& db = DatabaseManager::instance();
    QSqlDatabase database = db.database();
    
    qDebug() << "[SaleRepository] Iniciando pago de venta ID:" << saleId;
    
    // Iniciar transacción
    if (!database.transaction()) {
        qCritical() << "[SaleRepository] Error iniciando transacción para pagar venta";
        return false;
    }
    
    QSqlQuery query(database);
    
    // 1. Obtener información de la venta antes de actualizar
    query.prepare("SELECT customer_id, total, payment_status FROM sales WHERE id = :sale_id AND status = 'COMPLETED'");
    query.bindValue(":sale_id", saleId);
    
    if (!query.exec()) {
        qCritical() << "[SaleRepository] Error ejecutando query:" << query.lastError().text();
        qCritical() << "[SaleRepository] Query fue:" << query.lastQuery();
        database.rollback();
        return false;
    }
    
    if (!query.next()) {
        qCritical() << "[SaleRepository] No se encontró la venta con ID:" << saleId;
        database.rollback();
        return false;
    }
    
    int customerId = query.value(0).toInt();
    double total = query.value(1).toDouble();
    QString currentStatus = query.value(2).toString();
    
    qDebug() << "[SaleRepository] Venta encontrada - Cliente:" << customerId << "Total:" << total << "Estado actual:" << currentStatus;
    
    // Si ya está pagada, no hacer nada
    if (currentStatus == "PAID") {
        qDebug() << "[SaleRepository] Venta" << saleId << "ya está pagada";
        database.rollback();
        return true;
    }
    
    // 2. Actualizar estado de la venta a PAID
    QSqlQuery updateQuery(database);
    updateQuery.prepare(
        "UPDATE sales SET payment_status = 'PAID' "
        "WHERE id = :sale_id "
        "AND status = 'COMPLETED'"
    );
    updateQuery.bindValue(":sale_id", saleId);
    
    if (!updateQuery.exec()) {
        qCritical() << "[SaleRepository] Error marcando venta como pagada:" << updateQuery.lastError().text();
        database.rollback();
        return false;
    }
    
    int rowsAffected = updateQuery.numRowsAffected();
    qDebug() << "[SaleRepository] Venta" << saleId << "marcada como PAID. Filas afectadas:" << rowsAffected << "Monto:" << total;
    
    // 3. Actualizar current_debt del cliente
    QSqlQuery updateCustomerQuery(database);
    updateCustomerQuery.prepare(
        "UPDATE customers SET current_debt = COALESCE(current_debt, 0) - :amount WHERE id = :customer_id"
    );
    updateCustomerQuery.bindValue(":amount", total);
    updateCustomerQuery.bindValue(":customer_id", customerId);
    
    if (!updateCustomerQuery.exec()) {
        qCritical() << "[SaleRepository] Error actualizando deuda del cliente:" << updateCustomerQuery.lastError().text();
        database.rollback();
        return false;
    }
    
    qDebug() << "[SaleRepository] Deuda del cliente" << customerId << "reducida en" << total;
    
    // Confirmar transacción
    if (!database.commit()) {
        qCritical() << "[SaleRepository] Error confirmando transacción de pago individual";
        database.rollback();
        return false;
    }
    
    qDebug() << "[SaleRepository] Transacción de pago individual completada exitosamente";
    
    return true;
}

QString SaleRepository::generateNextInvoiceNumber()
{
    QSqlQuery query(DatabaseManager::instance().database());
    
    QString prefix = QDate::currentDate().toString("yyyyMMdd");
    int sequence = 1;
    QString invoiceNumber;
    
    // Intentar hasta encontrar un número único (máximo 100 intentos)
    for (int attempt = 0; attempt < 100; ++attempt) {
        // Obtener el último número de factura con este prefijo
        query.prepare(
            "SELECT invoice_number FROM sales "
            "WHERE invoice_number LIKE :prefix "
            "ORDER BY invoice_number DESC LIMIT 1"
        );
        query.bindValue(":prefix", prefix + "-%");

        if (!query.exec()) {
            qCritical() << "Error consultando números de factura:" << query.lastError().text();
            break;
        }

        if (query.next()) {
            QString lastInvoice = query.value(0).toString();
            // Formato: YYYYMMDD-XXXX
            QStringList parts = lastInvoice.split('-');
            if (parts.size() == 2 && parts[0] == prefix) {
                sequence = parts[1].toInt() + 1;
            }
        }

        invoiceNumber = QString("%1-%2").arg(prefix).arg(sequence, 4, 10, QChar('0'));
        
        // Verificar que no exista ya (por si acaso)
        query.prepare("SELECT COUNT(*) FROM sales WHERE invoice_number = :invoice");
        query.bindValue(":invoice", invoiceNumber);
        
        if (query.exec() && query.next() && query.value(0).toInt() == 0) {
            // Número único encontrado
            qDebug() << "Generated unique invoice number:" << invoiceNumber;
            return invoiceNumber;
        }
        
        // Si ya existe, incrementar y reintentar
        sequence++;
    }
    
    qCritical() << "Could not generate unique invoice number after 100 attempts";
    return invoiceNumber;
}

SaleRepository::SalesStats SaleRepository::getStatsForDate(const QDate& date)
{
    return getStatsForDateRange(date, date);
}

SaleRepository::SalesStats SaleRepository::getStatsForDateRange(const QDate& from, const QDate& to)
{
    SalesStats stats;
    QSqlQuery query(DatabaseManager::instance().database());
    
    // Solo contar ventas al CONTADO o con pago_status = PAID (crédito ya pagado)
    // Las ventas al crédito pendientes (CREDITO + PENDING/PARTIAL) no se cuentan como ventas completadas
    query.prepare(
        "SELECT COUNT(*) as count, COALESCE(SUM(total), 0) as total "
        "FROM sales "
        "WHERE DATE(created_at) BETWEEN :from AND :to "
        "AND status = 'COMPLETED' "
        "AND (payment_type = 'CONTADO' OR payment_status = 'PAID')"
    );
    query.bindValue(":from", from.toString(Qt::ISODate));
    query.bindValue(":to", to.toString(Qt::ISODate));

    if (query.exec() && query.next()) {
        stats.totalTransactions = query.value("count").toInt();
        stats.totalSales = query.value("total").toDouble();
        
        if (stats.totalTransactions > 0) {
            stats.averageTicket = stats.totalSales / stats.totalTransactions;
        }
    } else {
        qCritical() << "Error obteniendo estadísticas de ventas:" << query.lastError().text();
    }

    return stats;
}

QList<SaleRepository::DailySales> SaleRepository::getDailySalesInRange(const QDate& from, const QDate& to)
{
    QList<DailySales> dailySales;
    QSqlQuery query(DatabaseManager::instance().database());
    
    // Solo contar ventas al CONTADO o con payment_status = PAID
    query.prepare(
        "SELECT DATE(created_at) as sale_date, "
        "COUNT(*) as transaction_count, "
        "SUM(total) as total_sales "
        "FROM sales "
        "WHERE DATE(created_at) BETWEEN :from AND :to "
        "AND status = 'COMPLETED' "
        "AND (payment_type = 'CONTADO' OR payment_status = 'PAID') "
        "GROUP BY DATE(created_at) "
        "ORDER BY sale_date ASC"
    );
    query.bindValue(":from", from.toString(Qt::ISODate));
    query.bindValue(":to", to.toString(Qt::ISODate));

    if (query.exec()) {
        while (query.next()) {
            DailySales daily;
            daily.date = QDate::fromString(query.value("sale_date").toString(), Qt::ISODate);
            daily.transactionCount = query.value("transaction_count").toInt();
            daily.totalSales = query.value("total_sales").toDouble();
            dailySales.append(daily);
        }
    } else {
        qCritical() << "Error obteniendo ventas diarias:" << query.lastError().text();
    }

    return dailySales;
}

QList<SaleRepository::TopProduct> SaleRepository::getTopProducts(const QDate& from, const QDate& to, int limit)
{
    QList<TopProduct> topProducts;
    QSqlQuery query(DatabaseManager::instance().database());
    
    // Solo contar productos de ventas al CONTADO o con payment_status = PAID
    query.prepare(
        "SELECT si.product_id, si.product_name, "
        "SUM(si.quantity) as total_quantity, "
        "SUM(si.subtotal) as total_revenue "
        "FROM sale_items si "
        "INNER JOIN sales s ON si.sale_id = s.id "
        "WHERE DATE(s.created_at) BETWEEN :from AND :to "
        "AND s.status = 'COMPLETED' "
        "AND (s.payment_type = 'CONTADO' OR s.payment_status = 'PAID') "
        "GROUP BY si.product_id, si.product_name "
        "ORDER BY total_revenue DESC "
        "LIMIT :limit"
    );
    query.bindValue(":from", from.toString(Qt::ISODate));
    query.bindValue(":to", to.toString(Qt::ISODate));
    query.bindValue(":limit", limit);

    if (query.exec()) {
        while (query.next()) {
            TopProduct product;
            product.productId = query.value("product_id").toInt();
            product.productName = query.value("product_name").toString();
            product.quantitySold = query.value("total_quantity").toDouble();
            product.totalRevenue = query.value("total_revenue").toDouble();
            topProducts.append(product);
        }
    } else {
        qCritical() << "Error obteniendo productos más vendidos:" << query.lastError().text();
    }

    return topProducts;
}

Sale SaleRepository::mapFromQuery(const QSqlQuery& query)
{
    Sale sale;
    sale.id = query.value("id").toInt();
    sale.invoiceNumber = query.value("invoice_number").toString();
    sale.voucherType = query.value("voucher_type").toString();
    sale.customerId = query.value("customer_id").toInt();
    sale.customerName = query.value("customer_name").toString();
    sale.customerRuc = query.value("customer_ruc").toString();
    sale.customerBusinessName = query.value("customer_business_name").toString();
    sale.customerAddress = query.value("customer_address").toString();
    sale.subtotal = query.value("subtotal").toDouble();
    sale.tax = query.value("tax").toDouble();
    sale.discount = query.value("discount").toDouble();
    sale.total = query.value("total").toDouble();
    sale.paymentMethodId = query.value("payment_method_id").toInt();
    sale.paymentMethodName = query.value("payment_method_name").toString();
    sale.paymentType = query.value("payment_type").toString();
    sale.paymentStatus = query.value("payment_status").toString();
    sale.amountPaid = query.value("amount_paid").toDouble();
    sale.changeGiven = query.value("change_given").toDouble();
    sale.status = query.value("status").toString();
    sale.notes = query.value("notes").toString();
    sale.createdAt = QDateTime::fromString(query.value("created_at").toString(), Qt::ISODate);
    sale.createdBy = query.value("created_by").toString();
    
    // Nuevos campos de resumen de productos
    sale.storedItemCount = query.value("item_count").toInt();
    sale.productNames = query.value("product_names").toString();
    
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
